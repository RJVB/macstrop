# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4
#
# Copyright (c) 2013-2018 RJVB & The MacPorts Project
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
# This portgroup defines standard settings when using qmake with qt5-kde.
# Not to be used directly.
# Typical usage that allows install-from-scratch of a port that prefers qt5-kde
# but will still work when port:qt5 is already installed:
#
# set qt5.prefer_kde            yes
# PortGroup                     qmake5 1.0

# transfer control if qt5.using_kde isn't set, which is the case only
# when port:qt5-kde is installed and the Qt5 PortGroup has processed
# that fact.
if {![tbool qt5.using_kde]} {
    ui_warn "The qmake5-kde PortGroup shouldn't be called directly"
    # We don't allow ourselves to be called directly. This ensures
    # that we get all the options declarations from the mainstream
    # qmake5 PG, before it transfers control back to us.
    PortGroup                   qmake5 1.0
    return
}

# if we're here, that means port:qt5-kde is installed, qt5.using_kde is set and
# qmake5-1.0.tcl transferred control to us.

namespace eval qt5 {
    set dont_include_twice      yes
}
# include qt5-kde only once from here
PortGroup                       qt5-kde 1.0
namespace eval qt5 {
    unset dont_include_twice
}

if {![info exists qt5.add_spec]} {
    ### avoid defining these twice:

    # with the -r option, the examples do not install correctly (no source code)
    #     the install_sources target is not created in the Makefile(s)
    configure.cmd               ${qt_qmake_cmd}

    options qt5.add_spec qt5.debug_variant
    default qt5.add_spec        yes
    default qt5.debug_variants  yes

    configure.pre_args-replace  --prefix=${prefix} "PREFIX=${prefix}"
    configure.universal_args-delete \
                                --disable-dependency-tracking
}
options qt5.rewind_qmake_cache
default qt5.rewind_qmake_cache  yes

options qt5.unset_cflags qt5.unset_cxxflags
default qt5.unset_cflags        {}
default qt5.unset_cxxflags      {}

# this should be set to ${configure.ldflags} by default
default qt5.ldflags             {${configure.ldflags}}

### using port:qt5-kde
# we use a somewhat simpler qmake cookbook, which doesn't require the magic related
# to providing all Qt components through subports. We also provide a different +debug
# variant which dependents don't need to know anything about.

# qt5-kde does not currently support a debug variant, but does provide (some) debugging information
configure.pre_args-append       "CONFIG+=release"

# see https://trac.macports.org/ticket/53186
default destroot.destdir        "INSTALL_ROOT=${destroot}"

pre-configure {
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

    #
    # set QT_ARCH and QT_TARGET_ARCH manually since they may be
    #     incorrect in ${qt_mkspecs_dir}/qconfig.pri
    #     if qtbase was built universal
    #
    # -spec specifies build configuration (compiler, 32-bit/64-bit, etc.)
    #
    # set -arch x86_64 since macx-clang spec file assumes it is the default
    #
    # set QT and QMAKE values in a qt5::cache file
    # previously, they were set using configure.args
    # a qt5::cache file is used for two reasons
    #
    # 1) a change in Qt 5.7.1  made it more difficult to override sdk variables
    #    see https://codereview.qt-project.org/#/c/165499/
    #    see https://bugreports.qt.io/browse/QTBUG-56965
    #
    # 2) some ports (e.g. py-pyqt5 py-qscintilla2) call qmake indirectly and
    #    do not pass on the configure.args values
    #
    xinstall -m 755 -d ${qt5.top_level}
    if {[tbool qt5.rewind_qmake_cache]} {
        set qt5::cache [open "${qt5.top_level}/.qmake.cache" w 0644]
    } else {
        set qt5::cache [open "${qt5.top_level}/.qmake.cache" a 0644]
    }
    platform darwin {
        ## NB: 5.9 and newer apparently support true universal building and no longer
        ## require the muniversal PG approach. Mcalhoun's port:qt5 family support that,
        ## not us (sorry, too much complexity for something that's too niche for the
        ## expected profile of users interested in KF5).
        puts ${qt5::cache} "if(${qt_qmake_spec_64}) {"
        puts ${qt5::cache} "  QT_ARCH=x86_64"
        puts ${qt5::cache} "  QT_TARGET_ARCH=x86_64"
        puts ${qt5::cache} "  QMAKE_CFLAGS+=-arch x86_64"
        puts ${qt5::cache} "  QMAKE_CXXFLAGS+=-arch x86_64"
        puts ${qt5::cache} "  QMAKE_LFLAGS+=-arch x86_64"
        puts ${qt5::cache} "} else {"
        puts ${qt5::cache} "  QT_ARCH=i386"
        puts ${qt5::cache} "  QT_TARGET_ARCH=i386"
        puts ${qt5::cache} "}"
        # override QMAKE_MACOSX_DEPLOYMENT_TARGET set in ${prefix}/libexec/qt5/mkspecs/macx-clang/qmake.conf
        # see #50249
        puts ${qt5::cache} "QMAKE_MACOSX_DEPLOYMENT_TARGET=${macosx_deployment_target}"
        # respect configure.sdkroot if it exists
        if {${configure.sdkroot} ne ""} {
            puts ${qt5::cache} \
                QMAKE_MAC_SDK=[string tolower [join [lrange [split [lindex [split ${configure.sdkroot} "/"] end] "."] 0 end-1] "."]]
        }
    }
    # respect configure.compiler but still allow qmake to find correct Xcode clang based on SDK
    if { ${configure.compiler} ne "clang" || ${configure.ccache} } {
        if {${configure.ccache}} {
            set qt5::ccache "${prefix}/bin/ccache "
        } else {
            set qt5::ccache ""
        }
        puts ${qt5::cache} "QMAKE_CC=${qt5::ccache}${configure.cc}"
        puts ${qt5::cache} "QMAKE_CXX=${qt5::ccache}${configure.cxx}"
        puts ${qt5::cache} "QMAKE_LINK_C=${configure.cc}"
        puts ${qt5::cache} "QMAKE_LINK_C_SHLIB=${configure.cc}"
        puts ${qt5::cache} "QMAKE_LINK=${configure.cxx}"
        puts ${qt5::cache} "QMAKE_LINK_SHLIB=${configure.cxx}"
    }
    # add our compiler options
    if {${qt5.unset_cflags} ne {}} {
        puts ${qt5::cache} "QMAKE_CFLAGS-=${qt5.unset_cflags}"
    }
    if {${qt5.unset_cxxflags} ne {}} {
        puts ${qt5::cache} "QMAKE_CXXFLAGS-=${qt5.unset_cxxflags}"
    }
    puts ${qt5::cache} "QMAKE_CFLAGS+=${configure.cflags}"
    puts ${qt5::cache} "QMAKE_CXXFLAGS+=${configure.cxxflags}"

    set qt5::qt_version [qt5.active_version]

    # save certain configure flags
    set qmake5_cxx11_flags ""
    set qmake5_cxx_flags   ""
    set qmake5_l_flags     ""
    foreach flag ${configure.cxxflags} {
        if { ${flag} eq "-D_GLIBCXX_USE_CXX11_ABI=0" } {
            lappend qmake5_cxx11_flags ${flag}
        }
    }
    set qmake5_cxx11_flags [join ${qmake5_cxx11_flags} " "]
    set qmake5_cxx_flags   [join ${qmake5_cxx_flags} " "]
    set qmake5_l_flags     [join ${qmake5_l_flags}     " "]

    if {${configure.cxx_stdlib} ne ""} {
        if { [vercmp ${qt5::qt_version} 5.6] >= 0 } {
            if { ${configure.cxx_stdlib} ne "libc++" } {
                # override C++ flags set in ${prefix}/libexec/qt5/mkspecs/common/clang-mac.conf
                #    so value of ${configure.cxx_stdlib} can always be used
                puts ${qt5::cache} QMAKE_CXXFLAGS-=-stdlib=libc++
                puts ${qt5::cache} QMAKE_LFLAGS-=-stdlib=libc++
                puts ${qt5::cache} QMAKE_CXXFLAGS+=-stdlib=${configure.cxx_stdlib}
                puts ${qt5::cache} QMAKE_LFLAGS+=-stdlib=${configure.cxx_stdlib}
            }
            if {${qmake5_cxx11_flags} ne ""} {
                puts ${qt5::cache} QMAKE_CXXFLAGS+="${qmake5_cxx11_flags}"
            }
        } elseif { [vercmp ${qt5::qt_version} 5.5] >= 0 } {

        # always use the same standard library
        puts ${qt5::cache} QMAKE_CXXFLAGS+=-stdlib=${configure.cxx_stdlib}
        puts ${qt5::cache} QMAKE_LFLAGS+=-stdlib=${configure.cxx_stdlib}

        # override C++ flags set in ${prefix}/libexec/qt5/mkspecs/common/clang-mac.conf
        #    so value of ${configure.cxx_stdlib} can always be used
        if { ${configure.cxx_stdlib} ne "libc++" } {
            puts ${qt5::cache} QMAKE_CXXFLAGS_CXX11-=-stdlib=libc++
            puts ${qt5::cache} QMAKE_LFLAGS_CXX11-=-stdlib=libc++
            puts ${qt5::cache} QMAKE_CXXFLAGS_CXX11+=-stdlib=${configure.cxx_stdlib}
            puts ${qt5::cache} QMAKE_LFLAGS_CXX11+=-stdlib=${configure.cxx_stdlib}
        }
        if {${qmake5_cxx11_flags} ne ""} {
            puts ${qt5::cache} QMAKE_CXXFLAGS_CXX11+="${qmake5_cxx11_flags}"
        }
        } else {
            # always use the same standard library
            puts ${qt5::cache} QMAKE_CXXFLAGS+=-stdlib=${configure.cxx_stdlib}
            puts ${qt5::cache} QMAKE_LFLAGS+=-stdlib=${configure.cxx_stdlib}
            if {${qmake5_cxx11_flags} ne ""} {
                puts ${qt5::cache} QMAKE_CXXFLAGS+="${qmake5_cxx11_flags}"
            }
        }
    }
    if {${qmake5_cxx_flags} ne "" } {
        puts ${qt5::cache} QMAKE_CXXFLAGS+="${qmake5_cxx_flags}"
    }
    if {${qmake5_l_flags} ne "" } {
        puts ${qt5::cache} QMAKE_LFLAGS+="${qmake5_l_flags}"
    }

    # respect configure.optflags
    if {[vercmp ${qt5.version} 5.9] >= 0} {
# this is correct only if configure.optflags actually contains a -Os option!
#         puts ${qt5::cache} "CONFIG+=optimize_size"
        puts ${qt5::cache} "QMAKE_CFLAGS_OPTIMIZE_SIZE=${configure.optflags}"
    } else {
        puts ${qt5::cache} "QMAKE_CXXFLAGS_RELEASE~=s/-O.+/${configure.optflags}/g"
    }

    foreach flag ${qt5.cxxflags} {
        puts ${qt5::cache} "QMAKE_CXXFLAGS+=${flag}"
    }

    foreach flag ${qt5.ldflags} {
        puts ${qt5::cache} "QMAKE_LFLAGS+=${flag}"
    }

    foreach flag ${qt5.frameworkpaths} {
        puts ${qt5::cache} "QMAKE_FRAMEWORKPATH+=${flag}"
    }

    # no debug+release build support in qt5-kde

    close ${qt5::cache}
}

# kate: backspace-indents true; indent-pasted-text true; indent-width 4; keep-extra-spaces true; remove-trailing-spaces modified; replace-tabs true; replace-tabs-save true; syntax Tcl/Tk; tab-indents true; tab-width 4;
