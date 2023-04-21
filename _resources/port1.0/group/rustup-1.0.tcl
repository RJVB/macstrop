# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4
#
# Copyright (c) 2023 R.J.V. Bertin
# All rights reserved.
#
# Usage:
# PortGroup     rustup 1.1
#
# This PortGroup is for ports that require rust and/or cargo to be built
# but do not depend on it otherwise (port:clamav, for example). Rather than
# requiring the obligatory installation of port:rust and/or port:cargo,
# allow the port to use a temporary, private install from rustup.rs .

namespace eval rustup {
    # our directory:
    set currentportgroupdir [file dirname [dict get [info frame 0] file]]
    # ports may (have to) include us more than once
    if {![info exists includecounter]} {
        set includecounter  0
    }


    if {${includecounter} >= 1} {
        ui_debug "We don't include PG rustup more than once"
        return
    }

    proc use_rustup {} {
        return [expr [variant_exists rustup_build] && [variant_isset rustup_build]]
    }

    # should ports need to provide their own version of the RustUp install script;
    # without that, we will need the rust and/or cargo ports?
    # if {[file exists ${filespath}/rustup-install.sh]} {
        variant rustup_build conflicts no_rustup description {build this port using a private rust install from rustup.rs} {}
    #     variant no_rustup conflicts rustup_build description {force a build using port:rust and/or port:cargo} {}
        if {![variant_isset no_rustup] && \
                !([file exists ${prefix}/bin/rustc] && [file exists ${prefix}/bin/cargo])} {
            default_variants-append +rustup_build
            if {[variant_isset rustup_build]} {
                ui_debug "Build will use rustup by default"
            }
        }
    # }

    # The path where we install rustup.
    # NB NB: we need to access this variable via its namespace in
    # the post-X blocks below because they are not executed inside
    # our own namespace!
    set home    ${workpath}/.rustup

    if {![use_rustup]} {
        depends_build-append \
            bin:rustc:rust \
            bin:cargo:cargo
    } else {
        if {${os.platform} eq "darwin"} {
            # for gmktemp:
            depends_build-append \
                port:coreutils
        }
        set env(RUSTUP_HOME)    ${home}
        set env(CARGO_HOME)     ${home}/Cargo
        set env(PATH)           ${home}/Cargo/bin:$env(PATH)
    }

    post-fetch {
        # There is no way to guarantee that the rustup install script will always be the same
        # and that snapshots will continue to work. Ports would thus have to provide a copy
        # in their $filespath and keep it up-to-date (hence the interrogation above).
        # curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > $TMPDIR/install.sh
        if {![file exists ${rustup::home}/rustup-install.sh]} {
            xinstall -d ${rustup::home}
            curl fetch --remote-time --progress ui_progress_download \
                https://sh.rustup.rs \
                ${rustup::home}/rustup-install.sh
            platform darwin {
                reinplace "s|mktemp|gmktemp|g" ${rustup::home}/rustup-install.sh
            }
            file attributes ${rustup::home}/rustup-install.sh -permissions ug+x
        }
    }

    pre-extract {
        if {[rustup::use_rustup] && ![file exists ${rustup::home}/Cargo/bin/rustup]} {
            ui_msg "--->  Doing rustup install"
            system "${rustup::home}/rustup-install.sh --profile minimal --no-modify-path -y"
        }
    }

    pre-configure {
        ui_debug "PATH=$env(PATH)"
    }

    pre-build {
        ui_debug "PATH=$env(PATH)"
    }

    set includecounter [expr ${includecounter} + 1]

}
