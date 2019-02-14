# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4
#
# Copyright (c) 2019 R.J.V. Bertin
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
# PortGroup     LTO 1.0

# TODO: this probably still needs logic for cmake, currently already implemented in another PG

variant LTO description {build with link-time optimisation} {}
if {[variant_isset LTO]} {
    if {${configure.compiler} eq "cc" && ${os.platform} eq "linux"} {
        configure.cflags-append \
                    -ftracer -flto -fuse-linker-plugin -ffat-lto-objects
        configure.ldflags-append \
                    ${configure.optflags} -ftracer -flto -fuse-linker-plugin
    } elseif {[string match *clang* ${configure.compiler}]} {
#         if {${os.platform} ne "darwin"} {
#             ui_error "unsupported combination +LTO with configure.compiler=${configure.compiler}"
#             return -code error "Unsupported variant/compiler combination in ${subport}"
#         }
        # detect support for flto=thin but only with MacPorts clang versions (being a bit cheap here)
        set clang_version [string map {"macports-clang-" ""} ${configure.compiler}]
        if {"${clang_version}" ne "${configure.compiler}" && [vercmp ${clang_version} "4.0"] >= 0} {
            # the compiler supports "ThinLTO", use it
            set lto_flag                "-flto=thin"
        } else {
            set lto_flag                "-flto"
        }
        configure.cflags-append         ${lto_flag}
        configure.cxxflags-append       ${lto_flag}
        configure.objcflags-append      ${lto_flag}
        configure.objcxxflags-append    ${lto_flag}
        # ${configure.optflags} is a list, and that can lead to strange effects
        # in certain situations if we don't treat it as such here.
        foreach opt ${configure.optflags} {
            configure.ldflags-append    ${opt}
        }
        configure.ldflags-append        ${lto_flag}
        platform darwin {
            # the Mac linker will complain without explicit LTO cache directory
            pre-configure {
                xinstall -m 755 -d ${build.dir}/.lto_cache
            }
            configure.ldflags-append    -Wl,-cache_path_lto,${build.dir}/.lto_cache
        }
    } else {
        configure.cflags-append \
                    -ftracer -flto -fuse-linker-plugin -ffat-lto-objects
        configure.ldflags-append \
                    ${configure.optflags} -ftracer -flto -fuse-linker-plugin
    }
}

# Set up AR, NM and RANLIB to prepare for +LTO even if we don't end up using it
options configure.ar \
        configure.nm \
        configure.ranlib
if {[string match *clang* ${configure.compiler}]} {
    if {${os.platform} ne "darwin" || [string match macports-clang* ${configure.compiler}]} {
        # only MacPorts provides llvm-ar and family on Mac
        default configure.ar "[string map {"clang" "llvm-ar"} ${configure.cc}]"
        default configure.nm "[string map {"clang" "llvm-nm"} ${configure.cc}]"
        default configure.ranlib "[string map {"clang" "llvm-ranlib"} ${configure.cc}]"
        set LTO.custom_binaries 1
    }
} elseif {${os.platform} eq "linux"} {
    if {${configure.compiler} eq "cc"} {
        default configure.ar "[string map {"cc" "gcc-ar"} ${configure.cc}]"
        default configure.nm "[string map {"cc" "gcc-nm"} ${configure.cc}]"
        default configure.ranlib "[string map {"cc" "gcc-ranlib"} ${configure.cc}]"
        set LTO.custom_binaries 1
    } else {
        default configure.ar "[string map {"gcc" "gcc-ar"} ${configure.cc}]"
        default configure.nm "[string map {"gcc" "gcc-nm"} ${configure.cc}]"
        default configure.ranlib "[string map {"gcc" "gcc-ranlib"} ${configure.cc}]"
        set LTO.custom_binaries 1
    }
}
if {[info exists LTO.custom_binaries]} {
    configure.env-append \
        AR="${configure.ar}" \
        NM="${configure.nm}" \
        RANLIB="${configure.ranlib}"
} else {
    default configure.ar "ar"
    default configure.nm "nm"
    default configure.ranlib "ranlib"
}

