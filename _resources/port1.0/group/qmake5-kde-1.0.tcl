# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4
# $Id: qmake5-1.0.tcl 145157 2016-01-27 04:47:20Z mcalhoun@macports.org $

#
# Copyright (c) 2013-2016 The MacPorts Project
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
# This portgroup defines standard settings when using qmake with qt5-kde
#
# Usage:
# PortGroup                     qmake5-kde 1.0
#
# or
# set qt5.prefer_kde            yes
# PortGroup                     qmake5 1.0

ui_warn "qmake5-kde-1.0.tcl is currently a work-in-progress!"

### implement exit-immediately-if-already-read mechanism
PortGroup                       qt5-kde 1.0

# with the -r option, the examples do not install correctly (no source code)
#     the install_sources target is not created in the Makefile(s)
configure.cmd                   ${qt_qmake_cmd}
#configure.cmd                   ${qt_qmake_cmd} -r

### avoid defining these twice:
options qt5.add_spec qt5.debug_variant
default qt5.add_spec            yes
default qt5.debug_variants      yes

configure.pre_args-replace      --prefix=${prefix} "PREFIX=${prefix}"
configure.universal_args-delete --disable-dependency-tracking

if {![tbool qt5.using_kde]} {
    ui_error "qmake5-kde-1.0.tcl is used in a wrong context"
    return -code error "invalid use of qmake5-kde-1.0.tcl"
}

### using port:qt5-kde
# we use a somewhat simpler qmake cookbook, which doesn't require the magic related
# to providing all Qt components through subports. We also provide a different +debug
# variant which dependents don't need to know anything about.

if {[tbool qt5.add_spec]} {
    if {[variant_exists universal] && [variant_isset universal]} {
        set merger_configure_args(i386) \
                                "CONFIG+=\"x86\" -spec ${qt_qmake_spec_32}"
        set merger_configure_args(x86_64) \
                                    "-spec ${qt_qmake_spec_64}"
    } elseif {${qt_qmake_spec} ne ""} {
        configure.args-append   -spec ${qt_qmake_spec}
    }
}
configure.args-append           QT_ARCH=${build_arch} \
                                QT_TARGET_ARCH=${build_arch}

# qt5-kde does not currently support a debug variant, but does provide (some) debugging information
configure.pre_args-append       "CONFIG+=release"

default destroot.destdir        "INSTALL_ROOT=${destroot}"


### back to common code:

# override QMAKE_MACOSX_DEPLOYMENT_TARGET set in ${prefix}/libexec/qt5/mkspecs/macx-clang/qmake.conf
# see #50249
configure.args-append QMAKE_MACOSX_DEPLOYMENT_TARGET=${macosx_deployment_target}

# respect configure.sdkroot if it exists
if {${configure.sdkroot} ne ""} {
    configure.args-append \
        QMAKE_MAC_SDK=[string tolower [join [lrange [split [lindex [split ${configure.sdkroot} "/"] end] "."] 0 end-1] "."]]
}

pre-extract {
    if {[info exists configure.dir]} {
        # maintenance convenience: prevent growing .qmake.cache files
        file delete -force ${configure.dir}/.qmake.cache
    }
}

# a change in Qt 5.7.1  made it more difficult to override sdk variables
# see https://codereview.qt-project.org/#/c/165499/
# see https://bugreports.qt.io/browse/QTBUG-56965
pre-configure {
    xinstall -m 755 -d ${configure.dir}
    set cache [open "${configure.dir}/.qmake.cache" a 0644]
    puts ${cache} "QMAKE_MACOSX_DEPLOYMENT_TARGET=${macosx_deployment_target}"
    if {${configure.sdkroot} ne ""} {
        puts ${cache} \
            QMAKE_MAC_SDK=[string tolower [join [lrange [split [lindex [split ${configure.sdkroot} "/"] end] "."] 0 end-1] "."]]
    }
    close ${cache}
}

# respect configure.compiler but still allow qmake to find correct Xcode clang based on SDK
if { ${configure.compiler} ne "clang" } {
    configure.args-append \
        QMAKE_CC=${configure.cc} \
        QMAKE_CXX=${configure.cxx}
}

# override C++11 flags set in ${prefix}/libexec/qt5/mkspecs/common/clang-mac.conf
#    so value of ${configure.cxx_stdlib} can always be used
# RJVB: only use cxx_stdlib when it is actually set and not equal to libc++ already.
if {${configure.cxx_stdlib} ne ""} {
    if {${configure.cxx_stdlib} ne "libc++"} {
        configure.args-append \
            QMAKE_CXXFLAGS_CXX11-=-stdlib=libc++ \
            QMAKE_LFLAGS_CXX11-=-stdlib=libc++   \
            QMAKE_CXXFLAGS_CXX11+=-stdlib=${configure.cxx_stdlib} \
            QMAKE_LFLAGS_CXX11+=-stdlib=${configure.cxx_stdlib}
    }
    # ensure ${configure.cxx_stdlib} is used for C++ stdlib
    configure.args-append \
        QMAKE_CXXFLAGS+=-stdlib=${configure.cxx_stdlib} \
        QMAKE_LFLAGS+=-stdlib=${configure.cxx_stdlib}
}

configure.args-append \
        QMAKE_CXXFLAGS+="${configure.cxxflags}" \
        QMAKE_CFLAGS+="${configure.cflags}" \
        QMAKE_LFLAGS+="${configure.ldflags}"

# kate: backspace-indents true; indent-pasted-text true; indent-width 4; keep-extra-spaces true; remove-trailing-spaces modified; replace-tabs true; replace-tabs-save true; syntax Tcl/Tk; tab-indents true; tab-width 4;
