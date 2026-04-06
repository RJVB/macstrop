# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#
# Some mods for the git fetching functionality from "base" as used by the git*-1.1 PGs

options git.shallow_since
default git.shallow_since {}

options git.fetch_submodules
default git.fetch_submodules {yes}

rename portfetch::gitfetch portfetch::gitfetch_stock
pre-fetch {
    ui_debug "github-1.1 PG overloaded the gitfetch procedure!"
}
proc portfetch::gitfetch {args} {
    global worksrcpath patchfiles \
           git.url git.branch git.cmd git.shallow_since git.fetch_submodules

    if {${git.fetch_submodules}} {
        set fetchsubmodopt "--recurse-submodules"
        set shallowsubmodopt "--shallow-submodules"
    } else {
        set fetchsubmodopt ""
        set shallowsubmodopt ""
    }
    set options "--progress ${fetchsubmodopt}"
    if {${git.shallow_since} ne {}} {
        append options " --shallow-since ${git.shallow_since} ${shallowsubmodopt}"
    } elseif {${git.branch} eq ""} {
        # if we're just using HEAD, we can make a shallow repo
        append options " --depth=1 ${shallowsubmodopt}"
    }
    set cmdstring "${git.cmd} clone $options ${git.url} [shellescape ${worksrcpath}] 2>&1"
    ui_debug "Executing: $cmdstring"
    if {[catch {system $cmdstring} result]} {
        return -code error [msgcat::mc "Git clone failed"]
    }

    if {${git.branch} ne ""} {
        set env "GIT_DIR=[shellescape ${worksrcpath}/.git] GIT_WORK_TREE=[shellescape ${worksrcpath}]"
        set cmdstring "$env ${git.cmd} checkout ${fetchsubmodopt} ${git.branch} 2>&1"
        ui_debug "Executing $cmdstring"
        if {[catch {system $cmdstring} result]} {
            return -code error [msgcat::mc "Git checkout failed"]
        }
    }

    if {[info exists patchfiles]} {
        return [portfetch::fetchfiles]
    }

    return 0
}
