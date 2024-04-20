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

if {[variant_exists LTO]} {
    set LTO.disable_LTO yes
} elseif {[tbool LTO.disable_LTO]} {
    variant LTO description {stub variant: link-time optimisation disabled for this port} {
        pre-configure {
            ui_warn "The +LTO variant has been disabled and thus has no effect"
        }
        notes-append "Port ${subport} has been installed with a dummy +LTO variant!"
    }
} else {
    variant LTO description {build with link-time optimisation} {}
}
options LTO.supports_i386
default LTO.supports_i386 yes

namespace eval LTO {}

proc LTO::variant_enabled {v} {
    global LTO.disable_LTO
    if {${v} eq "LTO" && [tbool LTO.disable_LTO]} {
        return 0
    } else {
        return [variant_isset ${v}]
    }
}

if {[string match "macports-clang*" ${configure.compiler}]} {
    set LTO::mp_compiler_version [string map {"macports-clang-" ""} ${configure.compiler}]
} elseif {[string match "macports-gcc*" ${configure.compiler}]} {
    set LTO::mp_compiler_version [string map {"macports-gcc-" ""} ${configure.compiler}]
} else {
    set LTO::mp_compiler_version -1
}

# Set up AR, NM and RANLIB to prepare for +LTO even if we don't end up using it
options configure.ar \
        configure.nm \
        configure.ranlib \
        LTO.use_archive_helpers \
        LTO.cpuflags \
        LTO.compatcpu

# give the port a say over whether or not the selected helpers are used
default LTO.use_archive_helpers yes
default LTO.cpuflags {}
default LTO.compatcpu westmere
default LTO.compatflags {-msse4.1 -msse4.2 -msse3 -mssse3 -msse2 -msse -mmmx -mpclmul}

if {![info exists LTO.allow_ThinLTO]} {
    set LTO.allow_ThinLTO yes
}

if {![info exists LTO.allow_UseLLD]} {
    set LTO.allow_UseLLD yes
}

## NB: clang also supports -ffat-lto-objects from v17 and up
if {![info exists LTO.fat_LTO_Objects]} {
    set LTO.fat_LTO_Objects no
}

# NB
# FIXME
# We should ascertain that configure.{ar,nm,ranlib} be full, absolute paths!
# NB

if {${os.platform} eq "darwin"} {
    # the Mac linker will complain without explicit LTO cache directory
    # only applies to lto=thin mode but won't hurt with lto=full.
    #
    # For ports with use_configure=no, Portfiles need to call the function
    # in an appropriate location where compiler and build.dir are set
    # and before they inject ${configure.ldflags} where and how that's required.
    proc LTO.set_lto_cache {} {
        global configure.compiler configure.ldflags build.dir
        if {[LTO::variant_enabled LTO] && ${configure.compiler} ne "clang"} {
            xinstall -m 755 -d ${build.dir}/.lto_cache
            configure.ldflags-append    -Wl,-cache_path_lto,${build.dir}/.lto_cache
        }
    }
    post-destroot {
        if {[LTO::variant_enabled LTO] && ${configure.compiler} ne "clang"} {
            file delete -force ${build.dir}/.lto_cache
            set morecrud [glob -nocomplain -directory ${workpath}/.tmp/ thinlto-* cc-*.o lto-llvm-*.o]
            if {${morecrud} ne {}} {
                file delete -force {*}${morecrud}
            }
        }
    }
} else {
    post-destroot {
        if {[LTO::variant_enabled LTO]} {
            set morecrud [glob -nocomplain -directory ${workpath}/.tmp/ thinlto-* cc-*.o lto-llvm-*.o]
            if {${morecrud} ne {}} {
                file delete -force {*}${morecrud}
            }
        }
    }
}

# append the arguments in ${flags} to the option variable(s) in ${vars}
# LTO.flags_append configure.cflags "a b c"
# LTO.flags_append {configure.cflags configure.cxxflags} "a b c"
proc LTO.flags_append {vars flags} {
    foreach v ${vars} {
        foreach f ${flags} {
            ${v}-append ${f}
        }
    }
}

# custom version for configure.*flags option vars
proc LTO.configure.flags_append {vars flags} {
    foreach v ${vars} {
        foreach f ${flags} {
            configure.${v}-append ${f}
        }
    }
}

# out-of-line implementation so changes are made *now*.
# Qt5 has its own mechanism to set LTO flags so don't do anything
# if we end up being loaded for a build of Qt5 itself.
if {[LTO::variant_enabled LTO] && ![info exists building_qt5]} {
    # some projects have their own configure option for LTO (often --enable-lto);
    # use this if the port tells us to
    if {[info exists LTO.configure_option]} {
        ui_debug "LTO: setting custom configure option(s) \"${LTO.configure_option}\""
        configure.args-append           ${LTO.configure_option}
    } else {
        if {[string match *clang* ${configure.compiler}]} {
            # detect support for flto=thin but only with MacPorts clang versions (being a bit cheap here)
            set clang_version [string map {"macports-clang-" ""} ${configure.compiler}]
            if {[tbool LTO.allow_ThinLTO] && "${clang_version}" ne "${configure.compiler}" && [vercmp ${clang_version} "4.0"] >= 0} {
                # the compiler supports "ThinLTO", use it if allowed
                set lto_flags           "-flto=thin"
            } else {
                set lto_flags           "-flto"
            }
            if {[tbool LTO.fat_LTO_Objects] && (${LTO::mp_compiler_version} >= 17)} {
                set lto_flags           "${lto_flags} -ffat-lto-objects"
            }
        } else {
            if {${os.platform} eq "linux"} {
                set lto_flags           "-ftracer -flto=${build.jobs} -fuse-linker-plugin"
            } elseif {${configure.compiler} ne "cc"} {
                set lto_flags           "-ftracer -flto=${build.jobs}"
            }
            if {[tbool LTO.fat_LTO_Objects]} {
                set lto_flags           "${lto_flags} -ffat-lto-objects"
            }
        }
        ui_debug "LTO: setting LTO compiler and linker option(s) \"${lto_flags}\""
        if {![variant_isset universal] || [tbool LTO.supports_i386]} {
            LTO.configure.flags_append      {cflags \
                                            cxxflags \
                                            objcflags \
                                            objcxxflags} \
                                            ${lto_flags}
            # ${configure.optflags} is a list, and that can lead to strange effects
            # in certain situations if we don't treat it as such here.
            LTO.configure.flags_append      ldflags "${configure.optflags} ${lto_flags}"
        } else { # checking build_arch probably won't do what I thought here #  if {${build_arch} ne "i386"} 
            if {[info exists merger_configure_cflags(x86_64)]} {
                set merger_configure_cflags(x86_64) "{*}$merger_configure_cflags(x86_64) ${lto_flags}"
            } else {
                set merger_configure_cflags(x86_64) "${lto_flags}"
            }
            if {[info exists merger_configure_cxxflags(x86_64)]} {
                set merger_configure_cxxflags(x86_64) "{*}$merger_configure_cxxflags(x86_64) ${lto_flags}"
            } else {
                set merger_configure_cxxflags(x86_64) "${lto_flags}"
            }
            if {[info exists merger_configure_objcflags(x86_64)]} {
                set merger_configure_objcflags(x86_64) "{*}$merger_configure_objcflags(x86_64) ${lto_flags}"
            } else {
                set merger_configure_objcflags(x86_64) "${lto_flags}"
            }
            if {[info exists merger_configure_ldflags(x86_64)]} {
                set merger_configure_ldflags(x86_64) "{*}$merger_configure_ldflags(x86_64) ${lto_flags}"
            } else {
                set merger_configure_ldflags(x86_64) "${lto_flags}"
            }
            # ${configure.optflags} is a list, and that can lead to strange effects
            # in certain situations if we don't treat it as such here.
            foreach opt ${configure.optflags} {
                configure.ldflags-append    ${opt}
            }
            set merger_arch_flag            yes
        }
        if {${os.platform} eq "darwin" && ![tbool LTO.allow_ThinLTO]} {
            if {![variant_isset universal] || [tbool LTO.supports_i386]} {
                pre-configure {
                    LTO.set_lto_cache
                }
                if {[info exists LTO_needs_pre_build]} {
                    pre-build {
                        LTO.set_lto_cache
                    }
                }
            }
        }
    }
}

if {[string match *clang* ${configure.compiler}]} {
    if {${os.platform} ne "darwin" || [string match macports-clang* ${configure.compiler}]} {
        # only MacPorts provides llvm-ar and family on Mac
        if {![variant_isset universal] || [info exists universal_archs_supported]} {
            default configure.ar "[string map {"clang" "llvm-ar"} ${configure.cc}]"
            default configure.nm "[string map {"clang" "llvm-nm"} ${configure.cc}]"
#             default configure.ranlib "[string map {"clang" "llvm-ranlib"} ${configure.cc}]"
            # ranlib is done by llvm-ar
            default configure.ranlib "/bin/echo"
            set LTO.custom_binaries 1
        }
    }
    if {${os.platform} ne "darwin" \
            && [string match macports-clang* ${configure.compiler}]
            && [LTO::variant_enabled LTO]} {
        ## clang on ~Darwin doesn't like -Os -flto so remove that flag from the initial C*FLAGS
        ui_warn "Changing -Os for -O2 because of +LTO"
        configure.cflags-replace -Os -O2
        configure.objcflags-replace -Os -O2
        configure.cxxflags-replace -Os -O2
        configure.objcxxflags-replace -Os -O2
        configure.ldflags-replace -Os -O2
    }
} elseif {${os.platform} eq "linux"} {
    if {${configure.compiler} eq "cc"} {
        default configure.ar "[string map {"cc" "gcc-ar"} ${configure.cc}]"
        default configure.nm "[string map {"cc" "gcc-nm"} ${configure.cc}]"
        default configure.ranlib "[string map {"cc" "gcc-ranlib"} ${configure.cc}]"
        set LTO.custom_binaries 1
    } elseif {${configure.compiler} eq "gcc"} {
        default configure.ar "[string map {"gcc" "gcc-ar"} ${configure.cc}]"
        default configure.nm "[string map {"gcc" "gcc-nm"} ${configure.cc}]"
        default configure.ranlib "[string map {"gcc" "gcc-ranlib"} ${configure.cc}]"
        set LTO.custom_binaries 1
    } else {
        default configure.ar "[string map {"gcc" "gcc-ar"} ${configure.cc}]"
        default configure.nm "[string map {"gcc" "gcc-nm"} ${configure.cc}]"
#         default configure.ranlib "[string map {"gcc" "gcc-ranlib"} ${configure.cc}]"
        # done by gcc-ar
        default configure.ranlib "/bin/echo"
        set LTO.custom_binaries 1
    }
}
if {[info exists LTO.custom_binaries]} {
    pre-configure {
        if {[option LTO.use_archive_helpers]} {
            configure.env-append \
                "AR=${configure.ar}" \
                "NM=${configure.nm}" \
                "RANLIB=${configure.ranlib}"
        }
    }
    pre-build {
        if {[option LTO.use_archive_helpers]} {
            build.env-append \
                "AR=${configure.ar}" \
                "NM=${configure.nm}" \
                "RANLIB=${configure.ranlib}"
        }
    }
} else {
    # check if port:cctools is installed; if so, use its ar/nm/ranlib.
    # We could add a depends_build on port:cctools, but these commands will
    # be picked up from the path anyway, so accept this opportunistic
    # build dependency.
    if {[file exists ${prefix}/bin/ar]} {
        default configure.ar "/opt/local/bin/ar"
        default configure.nm "/opt/local/bin/nm"
        default configure.ranlib "/opt/local/bin/ranlib"
    } else {
        default configure.ar "/usr/bin/ar"
        default configure.nm "/usr/bin/nm"
        default configure.ranlib "/usr/bin/ranlib"
    }
}

variant cputuned conflicts cpucompat description {Build using -march=native for optimal tuning to your CPU} {}
variant cpucompat conflicts cputuned description {Build using some commonly supported SIMD settings for optimal cross-CPU tuning} {}

if {[variant_isset cputuned]} {
    default LTO.cpuflags "-march=native"
}
if {[variant_isset cpucompat]} {
    default LTO.cpuflags "-march=${LTO.compatcpu} [join ${LTO.compatflags} " "]"
}
pre-configure {
    if {[variant_isset cputuned] || [variant_isset cpucompat]} {
        LTO.configure.flags_append  {cflags \
                                    cxxflags \
                                    objcflags \
                                    objcxxflags \
                                    ldflags} \
                                    ${LTO.cpuflags}
    }
}

if {[info exists LTO_needs_pre_build]} {
    pre-build {
        if {[variant_isset cputuned] || [variant_isset cpucompat]} {
		  ui_debug "LTO: Appending CPU flags to compiler/linker flags: \"${LTO.cpuflags}\""
            LTO.configure.flags_append \
                                    {cflags \
                                    cxxflags \
                                    objcflags \
                                    objcxxflags \
                                    ldflags} \
                                    ${LTO.cpuflags}
        }
    }
}

if {[tbool LTO.allow_UseLLD]} {
    if {${os.platform} eq "darwin"} {
        variant use_lld conflicts universal description {use the LLD linker (not for 32bit building)} {}
    } else {
        variant use_lld description {use the LLD linker} {}
    }
    if {[variant_isset use_lld]} {
        if {${os.platform} eq "darwin"} {
            depends_build-append path:bin/ld64.lld-mp-17:lld-17
            set LLD "${prefix}/bin/ld64.lld-mp-17"
        } else {
            depends_build-append path:bin/ld.lld-mp-12:lld-12
            set LLD "${prefix}/bin/ld.lld-mp-12"
        }
        if {[string match "macports-clang*" ${configure.compiler}]} {
            # TODO: figure out when --ld-path= was introduced ...
            if {${LTO::mp_compiler_version} >= 15} {
                LTO.configure.flags_append {ldflags} "-fuse-ld=lld --ld-path=${LLD}"
            } else {
                LTO.configure.flags_append {ldflags} "-fuse-ld=${LLD}"
            }
        } else {
            pre-configure {
                ui_warn "+use_lld : the -fuse-ld may or may not be supported!"
                LTO.configure.flags_append {ldflags} "-fuse-ld=${LLD}"
            }
        }
    }
}
if {![variant_exists use_lld] || ![variant_isset use_lld]} {
    if {[string match "macports-clang*" ${configure.compiler}]} {
        if {${LTO::mp_compiler_version} >= 5} {
            # simple, unconditional "don't use lld" for clang compilers built to use lld by default
            LTO.configure.flags_append {ldflags} "-fuse-ld=ld"
        }
    }
}

variant builtwith description {Label the install with the compiler used} {}
if {[variant_isset builtwith]} {
    set usedCompiler [string map {"-" "_"} [file tail ${configure.cc}]]
    variant ${usedCompiler} requires builtwith description "placeholder variant to record the compiler used" {
        pre-configure {
            ui_warn "+builtwith+${usedCompiler} are just placeholder variants used only to label the install with the compiler used"
        }
    }
    default_variants-append +${usedCompiler}
}

proc LTO::callback {} {
    # this callback could really also handle the disable and allow switches!
    global supported_archs
    if {[variant_exists use_lld] && [variant_isset use_lld]} {
        # lld doesn't support 32bit architectures
        supported_archs-delete i386 ppc
    }
}
port::register_callback LTO::callback
