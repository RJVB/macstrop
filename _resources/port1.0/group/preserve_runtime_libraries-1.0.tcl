# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4

# Copyright (c) 2015 The MacPorts Project
# Copyright (c) 2016 R.J.V. Bertin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of Apple Computer, Inc. nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
# Usage:
# PortGroup     preserve_runtime_libraries 1.0
#
# in the post-destroot, call preserve_libraries with the directory
# holding the libraries to preserve and a filename pattern. Example:
#
# post-destroot {
#   preserve_libraries ${prefix}/lib "libwebp*.*.dylib libwebp.so.*"
# }
#
# This will create a copy of the pre-existing libraries not installed
# by the current ${subport} to be stored in ${prefix}/${srcdir}/previous/${subport}
# with a symlink in ${prefix}/${srcdir} . Effort is made to preserve
# existing previous versions so it should be safe to update a port multiple times
# without need to rebuild (all) dependents. Some projects do not use versioned
# libraries (boost on Mac, for instance). Non-rebuilt dependents thus see the
# new library without an automatic possibility to let them use a previous version.
# For such ports, `preserve_runtime_libraries_allow_unlinked` can be set; this
# copies all of the existing libraries matching the provided pattern (e.g. libboost*.dylib)
# into the repository. Dependents will need to be modified manually with `install_name_tool
# -change` to load the old version. Note that this can only be done for a single version ...
# but the MacStrop boost port has been patched so it now creates versioned libraries ...
# when the +preserve_runtime_libraries variant is used.
#
# Using a special repository makes it immediately clear which port a
# legacy runtime belongs to; the symlink makes it easy to test whether
# the copy is still used.
#
# A table of contents (.toc) file is generated named after the currently active version
# and variant of the port, listing which already preserved are being preserved and which
# ones are newly preserved (= the current versions), and which of those are exported
# at the location where dependencies expect them to be.
#
# Optionally, use `update_preserved_libraries [pattern]` to update the
# dependency information of the preserved libraries among each others,
# pointing them into the preservation directory. This is not logged in the
# TOC file!
#
# Under very specific conditions the algorithm can be instructed to preserve files
# currently installed by a different port, e.g. in libgcc13 that replaces libgcc8
# and other earlier versions. Set `preserve_foreign_runtime_libraries` to yes for this.

# Note that ports that depend on poppler via poppler-qt4-mac or
# poppler-qt5-mac do not need this trick to avoid rebuilding.


set preserve_runtime_library_dir "previous/${subport}"
options preserve_runtime_libraries_allow_unlinked \
        preserve_foreign_runtime_libraries
default preserve_runtime_libraries_allow_unlinked {no}
default preserve_foreign_runtime_libraries {no}

namespace eval PRL {
    proc variants {} {
        global PortInfo
        set variants ""
        if {[info exists PortInfo(variants)]} {
            foreach v $PortInfo(variants) {
                if {[variant_isset ${v}]} {
                    set variants "${variants}+${v}"
                }
            }
        }
        return ${variants}
    }
}

proc preserve_libraries {srcdir patternlist} {
    global prefix subport destroot preserve_runtime_library_dir version revision
    if {[variant_isset preserve_runtime_libraries]} {
        if {![file exists ${srcdir}]} {
            ui_debug "Source for previous runtime libraries (${srcdir}) does not exist"
        } elseif {[file type ${srcdir}] eq "directory"} {
            set prevdir "${preserve_runtime_library_dir}"
            xinstall -m 755 -d ${destroot}${srcdir}/${prevdir}
            ui_debug "preserve_libraries ${srcdir} ${patternlist}"
            set fd [open "/dev/stderr" "w"]
            if {![catch {set installed [lindex [registry_active ${subport}] 0]}] || [option preserve_foreign_runtime_libraries]} {
                if {[info exists installed]} {
                    set cVersion "-[lindex $installed 1]"
                    set cRevision [lindex $installed 2]
                    set cVariants [lindex $installed 3]
                } else {
                    # set the variables so we can construct a toc file with a sensible filename
                    set cVersion "@${version}"
                    set cRevision ${revision}
                    set cVariants [PRL::variants]
                }
                set tocFName "${destroot}${srcdir}/${prevdir}/${subport}${cVersion}-${cRevision}${cVariants}.toc"
                if {![catch {set nfd [open ${tocFName} "w"]} err]} {
                    close ${fd}
                    set fd ${nfd}
                    if {[info exists installed]} {
                        puts ${fd} "## Libraries saved from port:${subport}@${cVersion}_${cRevision}${cVariants}"
                    } else {
                        puts ${fd} "## Saving libraries installed by other ports!"
                    }
                    puts ${fd} "## currently active while destroot'ing port:${subport}@${version}_${revision}[PRL::variants] :"
                    flush ${fd}
                    set tocStartSize [file size ${tocFName}]
                }
            }
            set extra_preserved {}
            foreach pattern ${patternlist} {
                # first handle the preserved backups that already exist
                set existing_backups [glob -nocomplain ${srcdir}/${prevdir}/${pattern}]
                foreach l ${existing_backups} {
                    set lib [file tail ${l}]
                    set prevlib [file join ${destroot}${srcdir}/${prevdir} ${lib}]
                    if {![file exists ${prevlib}] &&
                            ([option preserve_runtime_libraries_allow_unlinked] || ![file exists ${destroot}${l}])} {
                        ui_debug "Preserving previous runtime shared library ${l} as ${prevlib}"
                        set perms [file attributes ${l} -permissions]
                        copy ${l} ${prevlib}
                        if {![file exists ${destroot}${srcdir}/${lib}]} {
                            if {[file type ${prevlib}] ne "link"} {
                                file attributes ${prevlib} -permissions ${perms}
                            }
                            ln -s [file join ${prevdir} ${lib}] ${destroot}${srcdir}/${lib}
                            puts ${fd} "#\[old,exported\] ln -s [file join ${prevdir} ${lib}] ${srcdir}/${lib}"
                        } else {
                            lappend extra_preserved ${l}
                            puts ${fd} "#\[old,hidden\] ${l}"
                        }
                    }
                }
                foreach t [glob -nocomplain "${srcdir}/${prevdir}/${subport}-*.toc"] {
                    set toc [file tail ${t}]
                    set prevtoc [file join ${destroot}${srcdir}/${prevdir} ${toc}]
                    if {![file exists ${prevtoc}]} {
                        ui_debug "Preserving previous runtime shared library toc ${t}"
                        set perms [file attributes ${t} -permissions]
                        copy ${t} ${prevtoc}
                        if {[file type ${prevtoc}] ne "link"} {
                            file attributes ${prevtoc} -permissions ${perms}
                        }
                        puts ${fd} "#\[old\] ${prevtoc}"
                    }
                }
                # now we can do the libraries to backup from ${prefix}/lib (srcdir) itself
                # any of those that are symlinks into ${prevdir} will be pruned because they
                # have already been handled.
                set current_libs [glob -nocomplain ${srcdir}/${pattern}]
                foreach l ${current_libs} {
                    set fport [registry_file_registered ${l}]
                    # registry_file_registered returns "0" for files not belonging to a port
                    # we give the port author the favour of the doubt and backup the file anyway.
                    if {${fport} eq "${subport}" || ${fport} eq "0" || [option preserve_foreign_runtime_libraries]} {
                        set lib [file tail ${l}]
                        set prevlib [file join ${destroot}${srcdir}/${prevdir} ${lib}]
                        if {![file exists ${prevlib}] &&
                                ([option preserve_runtime_libraries_allow_unlinked] || ![file exists ${destroot}${l}])} {
                            ui_debug "Preserving current runtime shared library ${l} as ${prevlib}"
                            set perms [file attributes ${l} -permissions]
                            copy ${l} ${prevlib}
                            if {![file exists ${destroot}${srcdir}/${lib}]} {
                                if {[file type ${prevlib}] ne "link"} {
                                    file attributes ${prevlib} -permissions ${perms}
                                    puts -nonewline ${fd} "#\[current\] ${l}"
                                }
                                ln -s [file join ${prevdir} ${lib}] ${destroot}${srcdir}/${lib}
                                puts -nonewline ${fd} "#\[current,exported\] ln -s [file join ${prevdir} ${lib}] ${srcdir}/${lib}"
                            } else {
                                lappend extra_preserved ${l}
                                puts -nonewline ${fd} "#\[current,hidden\] ${l}"
                            }
                            if {[option preserve_foreign_runtime_libraries] && ${fport} ne "0"} {
                                puts ${fd} " (provided by port:${fport})"
                            } else {
                                puts ${fd} ""
                            }
                        }
                    } else {
                        ui_info "not preserving runtime library ${l} that belongs to port:${fport} (preserve_foreign_runtime_libraries=[option preserve_foreign_runtime_libraries])"
                    }
                }
                if {"${existing_backups}" eq "" && "${current_libs}" eq ""} {
                    ui_info "preserve_libraries ${srcdir} \"${patternlist}\" preserved nothing for \"${pattern}\""
                    ui_info "\texisting backups found: \"${existing_backups}\""
                    ui_info "\tcurrent libraries: \"${current_libs}\""
                }
            }
            close ${fd}
            if {[info exists tocStartSize] && [file exists ${tocFName}] \
                    && [file size ${tocFName}] <= ${tocStartSize}} {
                file delete ${tocFName}
            }
            if {${extra_preserved} ne {}} {
                set hiddenMsg "Ports currently depending on the following libraries from the previous installed version of port:${subport} \
                    can be made to work with those previous libraries manually, pointing them to the now hidden copies \
                    with `install_name_tool -change ${prefix}/lib/X ${prefix}/lib/${preserve_runtime_library_dir}/X ${prefix}/path/to/dependent`:\n\
                    ${extra_preserved}"
                ui_msg ${hiddenMsg}
                notes-append ${hiddenMsg}
            }
        } else {
            ui_warn "Source for previous runtime libraries (${srcdir}) should be a directory"
        }
    } else {
        ui_debug "The preserve_runtime_libraries variant isn't set; ignoring the call to preserve_libraries"
    }
}

if {${os.platform} eq "darwin"} {
    proc update_preserved_libraries {{pattern ""}} {
        global prefix subport destroot preserve_runtime_library_dir
        if {[variant_isset preserve_runtime_libraries]} {
            if {${pattern} eq ""} {
                set pattern {}
                # construct a list of the current unique library IDs, mapping them to files
                # (which are probably symlinks of the type libfoo.X.dylib -> libfoo.X.Y.dylib).
                foreach lib [glob -nocomplain ${destroot}${prefix}/lib/${preserve_runtime_library_dir}/*.dylib] {
                    set soname [file tail [lindex [exec otool -D ${lib}] 1]]
                    set lib [file join ${prefix}/lib/${preserve_runtime_library_dir} ${soname}]
                    if {[file exists ${destroot}${lib}] && [lsearch ${pattern} ${lib}] eq -1} {
                        lappend pattern ${lib}
                    }
                }
                if {${pattern} eq {}} {
                    ui_debug "update_preserved_libraries found no files matching the available library IDs"
                    return
                }
            } else {
                set pattern [glob -nocomplain ${destroot}${prefix}/lib/${preserve_runtime_library_dir}/${pattern}]
            }
            ui_debug "Updating MachO dependency information in preserved libraries matching \"${pattern}\""
            # when preserving multiple directories, make them depend on each other
            # construct a dict that maps SO names to file names
            foreach lib ${pattern} {
                set otool [exec otool -D ${destroot}${lib}]
                dict set sonames ${lib} oldname [lindex ${otool} 1]
                dict set sonames ${lib} newname [string map [list ${destroot} ""] ${lib}]
            }
            if {[info exists sonames]} {
                ui_debug ${sonames}
            }
            # now make the preserved libraries depend on other preserved libraries.
            foreach lib ${pattern} {
                # set the ID to the new path
                system "install_name_tool -id [string map [list ${destroot} ""] ${lib}] ${destroot}${lib}"
                # update any dependencies on the other libraries installed by this port
                dict for {id info} ${sonames} {
                    dict with info {
                        system "install_name_tool -change ${oldname} ${newname} ${destroot}${lib}"
                    }
                }
            }
        } else {
            ui_debug "The preserve_runtime_libraries variant isn't set; ignoring the call to preserve_libraries"
        }
    }
} else {
    proc update_preserved_libraries {{pattern ""}} {
        global prefix subport destroot preserve_runtime_library_dir
        if {[variant_isset preserve_runtime_libraries]} {
            if {${pattern} eq ""} {
                set pattern "*.so.*"
            }
            # when preserving multiple directories, make them depend on each other
            # construct a dict that maps SO names to file names
            foreach lib [glob -nocomplain ${destroot}${prefix}/lib/${preserve_runtime_library_dir}/${pattern}] {
                dict set sonames ${lib} soname [file tail [exec patchelf --print-soname ${lib}]]
                dict set sonames ${lib} filename [file tail ${lib}]
            }
            # now make the preserved libraries depend on other preserved libraries.
            foreach lib [glob -nocomplain ${destroot}${prefix}/lib/${preserve_runtime_library_dir}/${pattern}] {
                set lrpath [exec patchelf --print-rpath ${lib}]
                # prepend the new installation path to the rpath
                system "patchelf --set-rpath ${prefix}/lib/${preserve_runtime_library_dir}:${lrpath} ${lib}"
                # update any dependencies on the other libraries installed by this port
                dict for {id info} ${sonames} {
                    dict with info {
                        # store a fully resolved DT_NEEDED entry to the preserved library
                        set sopath [file join ${prefix}/lib/${preserve_runtime_library_dir} ${soname}]
                        if {[file exists ${sopath}] || [file exists [file join ${destroot} ${sopath}]]} {
                            # but only if the file exists
                            system "patchelf --replace-needed ${soname} ${sopath} ${lib}"
                        }
                    }
                }
            }
        } else {
            ui_debug "The preserve_runtime_libraries variant isn't set; ignoring the call to update_preserved_libraries"
        }
    }
}

# allow ports to override the variant description
if {![variant_exists preserve_runtime_libraries]} {
    variant preserve_runtime_libraries description {Preserve the pre-existing runtime \
                                        libraries to ease the rebuilding load during upgrades.} {}
}

# kate: backspace-indents true; indent-pasted-text true; indent-width 4; keep-extra-spaces true; remove-trailing-spaces modified; replace-tabs true; replace-tabs-save true; syntax Tcl/Tk; tab-indents true; tab-width 4;

