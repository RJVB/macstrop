# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4

# Copyright (c) 2015, 2016 R.J.V. Bertin
# All rights reserved.
#
# Usage:
# PortGroup     kf5-WIP 1.0
#
# stuff for development of KF5 ports that aren't ready for prime-time
#
# Example used for testing (here port:kf5-ark)
# (NB: doesn't currently work fully on Linux, might be an issue in its cmake build system)
#
# PortGroup           kf5-WIP 1.0
# kf5.use_playground  ${kf5::playground}
# revision            wip1
# post-destroot {
#     xinstall -m 755 -d ${destroot}${prefix}/share/kxmlgui5/ark
#     ln -s ${kf5::playground}/share/kxmlgui5/ark/ark_part.rc ${destroot}${prefix}/share/kxmlgui5/ark
#     ln -s ${kf5::playground}/share/kxmlgui5/ark/arkui.rc ${destroot}${prefix}/share/kxmlgui5/ark
# }

namespace eval kf5 {
    variable playground "${prefix}/libexec/kf5-playground"
}

# a simple procedure for developing ports in a subprefix
proc kf5.use_playground {subprefix {autolink 1}} {
    global prefix subport kf5.applications_dir
    namespace upvar ::kf5 playground_linked linked
    namespace upvar ::kf5 playground_autolink dolink
    # tell CMake to install to the selected "sub prefix"
    cmake.install_prefix ${subprefix}
    ifplatform linux {
        global build_arch
        cmake.install_rpath-append \
                        ${subprefix}/lib/${build_arch}-linux-gnu
        configure.args-append \
                        -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON \
                        -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
        configure.ldflags-append \
                        "-Wl,-R,${prefix}/lib/${build_arch}-linux-gnu" \
                        "-Wl,-R,${subprefix}/lib/${build_arch}-linux-gnu"
        set kf5.applications_dir \
                        ${subprefix}/bin
    } else {
        # first replace
        configure.args-replace \
                        -DBUNDLE_INSTALL_DIR=${kf5.applications_dir} \
                        -DBUNDLE_INSTALL_DIR=${kf5.applications_dir}/WiP
        # then redefine
        set kf5.applications_dir ${kf5.applications_dir}/WiP
    }
    set kf5::playground ${subprefix}
    set linked no
    if {(${autolink} eq 1) || (${autolink} eq yes)} {
        set dolink yes
    } else {
        set dolink no
    }
    post-configure {
        ui_msg ">>> Port ${subport} is configured for installation to ${kf5::playground}"
    }
    notes-append "Port ${subport} is installed to testing grounds ${kf5::playground}"
}

proc kf5.link_from_playground {} {
    global destroot
    global prefix
    upvar #0 kf5::playground_linked linked
    if {[info exists linked] && (${linked} eq yes)} {
        ui_debug "kf5.link_from_playground already called"
        return
    }
    if {[file exists ${destroot}${kf5::playground}/include]} {
        foreach h [glob -nocomplain ${destroot}${kf5::playground}/include/*] {
            ln -s ${kf5::playground}/include/[file tail ${h}] ${destroot}${prefix}/include/
        }
    }
    if {[file exists ${destroot}${kf5::playground}/share/kservices5]
        || [file exists ${destroot}${kf5::playground}/share/kxmlgui5]} {
        # we cannot easily link back the share directory contents to where it should be;
        ui_msg "WARNING: directory \"${destroot}${kf5::playground}/share\" contains potentially crucial resources."
    }
    if {[file exists ${destroot}${kf5::playground}/lib/cmake]} {
        # link back the cmake modules to where they should be
        xinstall -m 755 -d [file dirname ${destroot}${prefix}/lib/cmake]
        foreach c [glob -nocomplain ${destroot}${kf5::playground}/lib/cmake/*] {
            ln -s ${kf5::playground}/lib/cmake/[file tail ${c}] ${destroot}${prefix}/lib/cmake/
        }
    }
    set linked yes
}

post-destroot {
    if {[info exists kf5::playground_autolink]} {
        # check if we need to do automatic restoring (the default). We do that here because this post-destroot
        # block should be the first such block. In other words, the calling Portfile should not yet have had
        # a chance to modify the destroot in ways that kf5.link_from_playground might overwrite.
        # kf5.link_from_playground checks itself if it already completed once.
        if {(${kf5::playground_autolink} eq yes) || (${kf5::playground_autolink} eq 1)} {
            ui_debug "doing requested auto kf5.link_from_playground (${kf5::playground_autolink})"
            kf5.link_from_playground
        }
    }
}

