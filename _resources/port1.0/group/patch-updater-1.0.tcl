# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#
# A port-maintainer-convenience PortGroup that hijacks the `port patch` phase to
# update/refresh patchfiles so they apply cleanly.
#
# This is done by creating a git repo in ${worksrcpath} (if required) and checking
# out a topic branch where each successfully committed patch gets a commit under
# its own filename.
# This commit is then used to create a new patchfile in a dedicated directory.
#
# As with a regular `port patch` phase, the procedure will abort when encountering
# a patchfile that does not apply; the failed hunks will then have to be fixed
# by hand.

# The procedure keeps track of which patches have been applied but is not yet
# clever enough to pick hand-fixed patchfiles from the dedicated target directory.
# The fixes must thus be applied to the original failing patchfile under ${filespath} !

if {[info exists PatchUpdater::currentportgroupdir]} {
    ui_debug "[dict get [info frame 0] file] has already been loaded"
    return
}

namespace eval PatchUpdater {
    # our directory:
    variable currentportgroupdir [file dirname [dict get [info frame 0] file]]
}

depends_patch-append port:git

set PatchUpdater::updatesfilespath "unset"
set PatchUpdater::gitignores 0

proc PatchUpdater::addIgnore {txt} {
    global worksrcpath
    if {[catch {exec fgrep -s -q ${txt} ${worksrcpath}/.gitignore}]} {
        set fd [open ${worksrcpath}/.gitignore a+]
        puts ${fd} ${txt}
        close ${fd}
        ui_debug "appended \"${txt}\" to [file tail ${worksrcpath}]/.gitignore"
        set PatchUpdater::gitignores [expr ${PatchUpdater::gitignores} +1]
    }
}

rename portpatch::patch_main portpatch::patch_main_real
pre-patch {
    ui_debug "PatchUpdater-1.1 PG overloaded the patch_main procedure!"
    if {![file exists ${worksrcpath}/.git] || [file type ${worksrcpath}/.git] ne "directory"} {
        ui_error "Using the patch-update PortGroup requires a git repository in \"${worksrcpath}\"!"
        return -code error "Not a git repository!"
    }
    if {[catch {system -W ${worksrcpath} "git checkout ${macportsuser}-${version}"}]} {
        system -W ${worksrcpath} "git checkout -b ${macportsuser}-${version}"
    }
    # let's make certain we don't create polluted patches!"
    PatchUpdater::addIgnore "*.orig"
    PatchUpdater::addIgnore "*.rej"
    PatchUpdater::addIgnore "*.kdev4"
    PatchUpdater::addIgnore ".kdev4"
    PatchUpdater::addIgnore ".*.swp"
    PatchUpdater::addIgnore "*.so"
    system -W ${worksrcpath} "git config user.email \"macportsuser@macports.org\" ; git config user.name \"${macportsuser}\""
    if {${PatchUpdater::gitignores}} {
        system -W ${worksrcpath} "git add .gitignore ; git commit -m \".gitignore\" .gitignore"
    }
    set PatchUpdater::updatesfilespath "${filespath}-updated-for-${version}"
    xinstall -d ${PatchUpdater::updatesfilespath}
}

proc portpatch::patch_main {args} {
    global UI_PREFIX

    set patches [list]

    if {[exists patchfiles]} {
        lappend patches {*}[option patchfiles]
    }
    if {[info procs muniversal::get_build_arch] != ""} {
        set arch [muniversal::get_build_arch]
        if {[exists patchfiles.${arch}]} {
            lappend patches {*}[option patchfiles.${arch}]
        }
    }

    if { ${patches} eq "" } {
        return 0
    }

    ui_notice "$UI_PREFIX [format [msgcat::mc "Updating patches for %s"] [option subport]]"

    foreach patch ${patches} {
        set patch_file [getdistname $patch]
        if {[file exists [option filespath]/$patch_file]} {
            lappend patchlist [option filespath]/$patch_file
        } elseif {[file exists [option distpath]/$patch_file]} {
            lappend patchlist [option distpath]/$patch_file
        } else {
            return -code error [format [msgcat::mc "Patch file %s is missing"] $patch]
        }
    }
    if {![info exists patchlist]} {
        return -code error [msgcat::mc "Patch files missing"]
    }

    set p1level no
    if {[string match *p1* [option patch.pre_args]]} {
        ui_info "Saving updated patches as -p1"
        set p1level yes
    } else {
        ui_info "Saving updated patches as the default -p0 patches"
    }

    set gzcat "[findBinary gzip $portutil::autoconf::gzip_path] -dc"
    set bzcat "[findBinary bzip2 $portutil::autoconf::bzip2_path] -dc"
    catch {set xzcat "[findBinary xz $portutil::autoconf::xz_path] -dc"}

    global workpath subport worksrcpath PatchUpdater::updatesfilespath
    set statefile [file join $workpath .macports.${subport}.state]
    set target_state_fd [open $statefile a+]
    flush ${target_state_fd}
    foreach patch $patchlist {
        set pfile [file tail $patch]
        if {[info exists arch]} {
            set pfile4arch "${arch}:${pfile}"
        } else {
            set pfile4arch "${pfile}"
        }
        if {![check_statefile patch $pfile4arch $target_state_fd]} {
            ui_info "$UI_PREFIX [format [msgcat::mc "Applying %s"] [file tail $patch]]"
            switch -- [file extension $patch] {
                .Z -
                .gz {
                    command_exec patch "$gzcat \"$patch\" | (" ")"
                    set patchname [file rootname ${patch}]
                }
                .bz2 {
                    command_exec patch "$bzcat \"$patch\" | (" ")"
                    set patchname [file rootname ${patch}]
                }
                .xz {
                    if {[info exists xzcat]} {
                        command_exec patch "$xzcat \"$patch\" | (" ")"
                    } else {
                        return -code error [msgcat::mc "xz binary not found; port needs to add 'depends_patch bin:xz:xz'"]
                    }
                    set patchname [file rootname ${patch}]
                }
                default {
                    command_exec patch "" "< '$patch'"
                    set patchname "${patch}"
                }
            }
            system -W ${worksrcpath} "git add -v ."
            system -W ${worksrcpath} "git commit -m \"${patch}\" ."
            # patchname can be in a subdir of filespath
            set pf [string map [list [option filespath] ""] ${patchname}]
            xinstall -d ${PatchUpdater::updatesfilespath}/[file dirname ${pf}]
            if {${p1level}} {
                system -W ${worksrcpath} "git show > ${PatchUpdater::updatesfilespath}/${pf}"
            } else {
                system -W ${worksrcpath} "git show --no-prefix > ${PatchUpdater::updatesfilespath}/${pf}"
            }
            # A-OK, we can register the patch as having been applied.
            write_statefile patch $pfile4arch $target_state_fd
        }
    }
    close ${target_state_fd}
    ui_msg "Updated/refreshed patches are in ${PatchUpdater::updatesfilespath} (uncompressed!)"
    ui_warn "NB NB Any comments or other non-patch content will have to be restored manually!"
    return 0
}


##########################################################################################
# register callbacks
##########################################################################################
# proc PatchUpdater::test {} {
# }
# port::register_callback PatchUpdater::test
