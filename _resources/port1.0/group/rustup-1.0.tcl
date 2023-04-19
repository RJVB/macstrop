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
}

if {${rustup::includecounter} >= 1} {
    ui_debug "We don't include PG rustup more than once"
    return
}

proc use_rustup {} {
    return [expr [variant_exists rustup_build] && [variant_isset rustup_build]]
}

if {[file exists ${filespath}/rustup-install.sh]} {
    # ports need to provide their own version of the RustUp install script;
    # without that, we will need the rust and/or cargo ports.
    variant rustup_build conflicts no_rustup description {build this port using a private rust install from rustup.rs} {}
#     variant no_rustup conflicts rustup_build description {force a build using port:rust and/or port:cargo} {}
    if {![variant_isset no_rustup] && !([file exists ${prefix}/bin/rustc] && [file exists ${prefix}/bin/cargo])} {
        default_variants-append +rustup_build
        if {[variant_isset rustup_build]} {
            ui_debug "Build will use rustup by default"
        }
    }
}

if {![use_rustup]} {
    depends_build-append \
        bin:rustc:rust \
        bin:cargo:cargo
}

post-extract {
    if {[use_rustup]} {
        ui_msg "Doing rustup install"
    }
}

set rustup::includecounter [expr ${rustup::includecounter} + 1]
