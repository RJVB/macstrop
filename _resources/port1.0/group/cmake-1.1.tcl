# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4
#
# Copyright (c) 2009 Orville Bennett <illogical1 at gmail.com>
# Copyright (c) 2010-2015 The MacPorts Project
# Copyright (c) 2015-2018 R.J.V. Bertin
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
# PortGroup     cmake 1.1

namespace eval cmake {
    # our directory:
    variable currentportgroupdir [file dirname [dict get [info frame 0] file]]
}

options                             cmake.build_dir \
                                    cmake.source_dir \
                                    cmake.generator \
                                    cmake.generator_blacklist \
                                    cmake.build_type \
                                    cmake.install_prefix \
                                    cmake.install_rpath \
                                    cmake.module_path \
                                    cmake_share_module_dir \
                                    cmake.out_of_source \
                                    cmake.set_osx_architectures

## Explanation of and default values for the options defined above ##

# out-of-source builds are the default
default cmake.out_of_source         yes

# cmake.build_dir defines where the build will take place
default cmake.build_dir             {${workpath}/build}
# cmake.source_dir defines where CMake will look for the toplevel CMakeLists.txt file
default cmake.source_dir            {${worksrcpath}}

# set CMAKE_OSX_ARCHITECTURES when necessary.
# This can be deactivated when (non-Apple) compilers are used
# that don't support the corresponding -arch options.
default cmake.set_osx_architectures yes

# cmake.build_type defines the type of build; it defaults to "MacPorts"
# which means only the compiler options set through configure.c*flags and configure.optflags
# are used, plus those set in the port's CMake files. Alternative pre-defined types are
# Release, Debug, RelWithDebInfo and MinSizeRel; "None" should work like "MacPorts".
default cmake.build_type            MacPorts

# cmake-based ports may want to modify the install prefix
default cmake.install_prefix        {${prefix}}

# minimal/initial value for the install rpath:
default cmake.install_rpath         {${prefix}/lib}

# standard place to install extra CMake modules
default cmake_share_module_dir      {${prefix}/share/cmake/Modules}
# extra locations to search for modules can be specified with
# cmake.module_path; they come after ${cmake_share_module_dir}
default cmake.module_path           {}

# Set cmake.debugopts to the desired compiler debug options (or an empty string) if you want to
# use custom options with the +debug variant.

# CMake provides several different generators corresponding to different utilities
# (and IDEs) used for building the sources. We support "Unix Makefiles" (the default)
# and Ninja, a leaner-and-meaner alternative.
#
# In the Portfile, use
#
# cmake.generator Ninja
# or
# cmake.generator "Unix Makefiles"
# or even
# cmake.generator "Eclipse CDT4 - Ninja"
# if maintaining the port means editing it using an IDE of choice.
#
# If ports package code that cannot be built with certain generators this
# fact can be signalled:
#
# cmake.generator_blacklist <generator-pattern>
# (patterns are case-insensitive, e.g. "*ninja*")
#
if {[vercmp [macports_version] 2.5.3] <= 0} {
    default cmake.generator             {"CodeBlocks - Unix Makefiles"}
} else {
    default cmake.generator             "CodeBlocks - Unix Makefiles"
}
default cmake.generator_blacklist   {}
# CMake generates Unix Makefiles that contain a special "fast" install target
# which skips the whole "let's see if there's anything left to (re)build before
# we install" you normally get with `make install`. That check should be
# redundant in normal destroot steps, because we just completed the build step.
default destroot.target             install/fast

## ############################################################### ##

# make sure cmake is available:
# can use cmake or cmake-devel; default to cmake if not installed
depends_build-append                path:bin/cmake:cmake
depends_skip_archcheck-append       cmake


proc cmake::rpath_flags {} {
    global prefix
    if {[llength [option cmake.install_rpath]]} {
        # make sure a single ${cmake.install_prefix} is included in the rpath
        # careful, we are likely to be called more than once.
        if {[lsearch -exact [option cmake.install_rpath] [option cmake.install_prefix]/lib] == -1} {
            cmake.install_rpath-append [option cmake.install_prefix]/lib
        }
        return [list \
            -DCMAKE_BUILD_WITH_INSTALL_RPATH:BOOL=ON \
            -DCMAKE_INSTALL_RPATH="[join [option cmake.install_rpath] \;]"
        ]
    }
    # always build with full RPATH; this is the default on Mac.
    # Let ports deactivate it explicitly if they need to.
    return -DCMAKE_BUILD_WITH_INSTALL_RPATH:BOOL=ON
}

proc cmake::system_prefix_path {} {
    global prefix
    if {[option cmake.install_prefix] ne ${prefix}} {
        return [list \
                 -DCMAKE_SYSTEM_PREFIX_PATH="${prefix}\;[option cmake.install_prefix]\;/usr"
        ]
    } else {
        return [list \
                 -DCMAKE_SYSTEM_PREFIX_PATH="${prefix}\;/usr"
        ]
    }
}

proc cmake::module_path {} {
    if {[llength [option cmake.module_path]]} {
        set modpath "[join [concat [option cmake_share_module_dir] [option cmake.module_path]] \;]"
    } else {
        set modpath [option cmake_share_module_dir]
    }
    return [list \
        -DCMAKE_MODULE_PATH="${modpath}" \
        -DCMAKE_PREFIX_PATH="${modpath}"
    ]
}

proc cmake::build_dir {} {
    if {[option cmake.out_of_source]} {
        return [option cmake.build_dir]
    }
    return [option cmake.source_dir]
}

option_proc cmake.generator cmake::handle_generator
proc cmake::handle_generator {option action args} {
    global cmake.generator destroot destroot.target build.cmd build.post_args
    global depends_build destroot.post_args build.jobs subport
    if {${action} eq "set"} {
        switch -glob [lindex ${args} 0] {
            "*Unix Makefiles*" {
                ui_debug "Selecting the 'Unix Makefiles' generator ($args)"
                depends_build-delete \
                                port:ninja
                depends_skip_archcheck-delete \
                                ninja
                build.cmd       make
                build.post_args VERBOSE=ON
                destroot.target install/fast
                destroot.destdir \
                                DESTDIR=${destroot}
                # unset the DESTDIR env. variable if it has been set before
                destroot.env-delete \
                                DESTDIR=${destroot}
#                     proc ui_progress_info {string} {
#                         if {[scan $string "\[%d%%\] " perc] == 1} {
#                             return $perc
#                         } else {
#                             return -1
#                         }
#                     }
            }
            "*Ninja" {
                ui_debug "Selecting the Ninja generator ($args)"
                depends_build-append \
                                port:ninja
                depends_skip_archcheck-append \
                                ninja
                build.cmd       ninja
                # force Ninja not to exceed the probably-expected CPU load by too much;
                # for larger projects one can reach as much as build.jobs*2 CPU load otherwise.
                # inspired by the old guideline as many compile jobs as you have CPUs, plus 1.
                build.post_args -l[expr ${build.jobs} + 1] -v
                destroot.target install
                # ninja needs the DESTDIR argument in the environment
                destroot.destdir
                destroot.env-append DESTDIR=${destroot}
            }
            default {
                if {[llength $args] != 1} {
                    set msg "cmake.generator requires a single value (not \"${args}\")"
                } else {
                    set msg "The \"${args}\" generator is not currently known/supported (cmake.generator is case-sensitive!)"
                }
                if {[file tail ${cmake::currentportgroupdir}] eq "group"} {
                    # we're not being run from the registry so we can raise errors
                    return -code error ${msg}
                } else {
                    ui_error "${msg} (ignoring)"
                }
            }
        }
    }
}

default configure.dir {[cmake::build_dir]}
default build.dir {${configure.dir}}
default build.post_args VERBOSE=ON

# cache the configure.ccache variable (it will be overridden in the pre-configure step)
set cmake::ccache_cache ${configure.ccache}
# idem for distcc
set cmake::distcc_cache ${configure.distcc}

# tell CMake to use ccache via the CMAKE_<LANG>_COMPILER_LAUNCHER variable
# and unset the global configure.ccache option which is not compatible
# with CMake. Ditto for distcc.
# See https://stackoverflow.com/questions/1815688/how-to-use-ccache-with-cmake
proc cmake::ccaching {} {
    global prefix
    namespace upvar ::cmake ccache_cache cccache
    if {${cccache} && [file exists ${prefix}/bin/ccache]} {
        return [list \
            -DCMAKE_C_COMPILER_LAUNCHER=${prefix}/bin/ccache \
            -DCMAKE_CXX_COMPILER_LAUNCHER=${prefix}/bin/ccache]
    }
}
proc cmake::distccing {} {
    global prefix
    namespace upvar ::cmake distcc_cache distcc
    namespace upvar ::cmake ccache_cache cccache
    # "base" will handle the case where ccache and distcc are both used.
    if {${distcc} && !${cccache}} {
        return [list \
            -DCMAKE_C_COMPILER_LAUNCHER=distcc \
            -DCMAKE_CXX_COMPILER_LAUNCHER=distcc]
    }
}


configure.cmd       ${prefix}/bin/cmake

# appropriate default settings for configure.pre_args
# variables are grouped thematically, with the more important ones
# at the beginning or end for somewhat easier at-a-glance verification.
# Policy 25=new: identify Apple Clang as AppleClang to ensure
#                consistency in compiler feature determination
# Policy 60=new: don't rewrite ${prefix}/lib/libfoo.dylib as -lfoo
default configure.pre_args {[list \
                    -DCMAKE_BUILD_TYPE=${cmake.build_type} \
                    -DCMAKE_INSTALL_PREFIX="${cmake.install_prefix}" \
                    -DCMAKE_INSTALL_NAME_DIR="${cmake.install_prefix}/lib" \
                    {*}[cmake::system_prefix_path] \
                    {*}[cmake::ccaching] \
                    {*}[cmake::distccing] \
                    {-DCMAKE_C_COMPILER="$CC"} \
                    {-DCMAKE_CXX_COMPILER="$CXX"} \
                    -DCMAKE_POLICY_DEFAULT_CMP0025=NEW \
                    -DCMAKE_POLICY_DEFAULT_CMP0060=NEW \
                    -DCMAKE_VERBOSE_MAKEFILE=ON \
                    -DCMAKE_COLOR_MAKEFILE=ON \
                    -DCMAKE_FIND_FRAMEWORK=LAST \
                    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
                    {*}[cmake::module_path] \
                    {*}[cmake::rpath_flags] \
                    -Wno-dev
]}

# make sure configure.args is set but don't reset it
configure.args-append

default configure.post_args {[option cmake.source_dir]}

# CMake honors set environment variables CFLAGS, CXXFLAGS, and LDFLAGS when it
# is first run in a build directory to initialize CMAKE_C_FLAGS,
# CMAKE_CXX_FLAGS, CMAKE_[EXE|SHARED|MODULE]_LINKER_FLAGS. However, be aware
# that a CMake script can always override these flags when it runs, as they
# are frequently set internally in functions of other CMake build variables!
#
# Attention: If you want to be sure that no compiler flags are passed via
# configure.args, you have to manually clear configure.optflags, as it is set
# to "-Os" by default and added to all language-specific flags. If you want to
# turn off optimization, explicitly set configure.optflags to "-O0".

# TODO: Handle configure.objcflags (cf. to CMake upstream ticket #4756
#       "CMake needs an Objective-C equivalent of CMAKE_CXX_FLAGS"
#       <https://public.kitware.com/Bug/view.php?id=4756>)

# TODO: Handle the Fortran-specific configure.* variables:
#       configure.fflags, configure.fcflags, configure.f90flags

# TODO: Handle the Java-specific configure.classpath variable.

pre-configure {
    # create the build directory as the first step
    file mkdir ${configure.dir}

    # check and bail early if we'd be using an incompatible cmake generator
    foreach genpattern ${cmake.generator_blacklist} {
        if {[string match -nocase ${genpattern} ${cmake.generator}]} {
            ui_error "port:${subport} doesn't support CMake's ${cmake.generator} generator"
            return -code error "unsupported CMake generator requested (port:${subport})"
        }
    }

    # The environment variable CPPFLAGS is not considered by CMake.
    # (CMake upstream ticket #12928 "CMake silently ignores CPPFLAGS"
    # <https://www.cmake.org/Bug/view.php?id=12928>).
    #
    # But adding -I${prefix}/include to CFLAGS/CXXFLAGS is a bad idea.
    # If any other flags are needed, we need to add them.

    # In addition, CMake provides build-type-specific flags for
    # Release (-O3 -DNDEBUG), Debug (-g), MinSizeRel (-Os -DNDEBUG), and
    # RelWithDebInfo (-O2 -g -DNDEBUG). If the configure.optflags have been
    # set (-Os by default), we have to remove the optimisation flags from
    # the concerned Release build type so that configure.optflags
    # gets honored (Debug used by the +debug variant does not set
    # optimisation flags by default).
    # We use a custom BUILD_TYPE (MacPorts) so we can simply append all desired
    # arguments to the CFLAGS and CXXFLAGS env. variables, which will be used
    # to set CMAKE_C_FLAGS and CMAKE_CXX_FLAGS, and those will control the build.
    if {![variant_isset debug]} {
        configure.cflags-append     -DNDEBUG
        configure.cxxflags-append   -DNDEBUG
    }

    # process ${configure.cppflags} because CMake ignores $CPPFLAGS
    if {${configure.cppflags} ne ""} {
        set cppflags [split ${configure.cppflags}]
        # reset configure.cppflags; we don't want options in double in CPPFLAGS and CFLAGS/CXXFLAGS
        configure.cppflags
        # copy the cppflags arguments one by one into cflags and family
        # CMake does have an INCLUDE_DIRECTORIES variable but setting it from the commandline
        # doesn't have the intended effect (any longer).
        foreach flag ${cppflags} {
            configure.cflags-append     ${flag}
            configure.cxxflags-append   ${flag}
            # append to the ObjC flags too, even if CMake ignores them:
            configure.objcflags-append  ${flag}
            configure.objcxxflags-append   ${flag}
        }
        ui_debug "CPPFLAGS=\"${cppflags}\" inserted into CFLAGS=\"${configure.cflags}\" CXXFLAGS=\"${configure.cxxflags}\""
    }

    configure.pre_args-prepend "-G \"[join ${cmake.generator}]\""
    # undo a counterproductive action from the debug PG:
    configure.args-delete -DCMAKE_BUILD_TYPE=debugFull
    # set matching CMAKE_AR and CMAKE_RANLIB when using a macports-clang compiler
    # (and they're not set explicitly by the port)
    # NB NB NB!
    # FIXME!
    # These should be set to absolute, full paths. We ought to check for that.
    # NB NB NB!
    if {[info exists configure.ar] && [info exists configure.nm] && [info exists configure.ranlib]} {
        if {[option LTO.use_archive_helpers]} {
            if {[string first "DCMAKE_AR=" ${configure.args}] eq -1} {
                configure.args-append \
                                -DCMAKE_AR="${configure.ar}"
            }
            if {[string first "DCMAKE_NM=" ${configure.args}] eq -1} {
                configure.args-append \
                                -DCMAKE_NM="${configure.nm}"
            }
            if {[string first "DCMAKE_RANLIB=" ${configure.args}] eq -1} {
                configure.args-append \
                                -DCMAKE_RANLIB="${configure.ranlib}"
            }
        }
    } elseif {[string match *clang++-mp* ${configure.cxx}]} {
        if {[string first "DCMAKE_AR=" ${configure.args}] eq -1} {
            configure.args-append \
                                -DCMAKE_AR=[string map {"clang++" "llvm-ar"} ${configure.cxx}]
        }
        if {[string first "DCMAKE_NM=" ${configure.args}] eq -1} {
            configure.args-append \
                                -DCMAKE_NM=[string map {"clang++" "llvm-nm"} ${configure.cxx}]
        }
        if {[string first "DCMAKE_RANLIB=" ${configure.args}] eq -1} {
            configure.args-append \
                                -DCMAKE_RANLIB=[string map {"clang++" "llvm-ranlib"} ${configure.cxx}]
        }
    } elseif {[string match *clang-mp* ${configure.cc}]} {
        if {[string first "DCMAKE_AR=" ${configure.args}] eq -1} {
            configure.args-append \
                                -DCMAKE_AR=[string map {"clang" "llvm-ar"} ${configure.cc}]
        }
        if {[string first "DCMAKE_NM=" ${configure.args}] eq -1} {
            configure.args-append \
                                -DCMAKE_NM=[string map {"clang" "llvm-nm"} ${configure.cc}]
        }
        if {[string first "DCMAKE_RANLIB=" ${configure.args}] eq -1} {
            configure.args-append \
                                -DCMAKE_RANLIB=[string map {"clang" "llvm-ranlib"} ${configure.cc}]
        }
    }
    if {[info exists qt_qmake_spec]} {
        if {([string first "-DCMAKE_MKPEC" ${configure.pre_args}] == -1)
            && ([string first "-DCMAKE_MKPEC" ${configure.args}] == -1)
            && ([string first "-DCMAKE_MKPEC" ${configure.post_args}] == -1)} {
            configure.args-append \
                                "-DCMAKE_MKSPEC=${qt_qmake_spec}"
        } else {
            ui_debug "CMAKE_MKSPEC already set"
        }
    }

    # The configure.ccache variable has been cached so we can restore it in the post-configure
    # (pre-configure and post-configure are always run in a single `port` invocation.)
    configure.ccache        no
    configure.distcc        no
    # surprising but intended behaviour that's impossible to work around more gracefully:
    # overriding configure.ccache fails if the user set it directly from the commandline
    if {[tbool configure.ccache]} {
        ui_error "Please don't use configure.ccache=yes on the commandline for port:${subport}, use configureccache=yes"
        return -code error "invalid invocation (port:${subport})"
    }
    if {${cmake::ccache_cache}} {
        ui_info "        (using ccache)"
    }
    if {[tbool configure.distcc]} {
        ui_error "Please don't use configure.distcc=yes on the commandline for port:${subport}, use configuredistcc=yes"
        return -code error "invalid invocation (port:${subport})"
    }
    if {${cmake::distcc_cache}} {
        ui_info "        (using distcc)"
    }
}

post-configure {
    # restore configure.ccache:
    if {[info exists cmake::ccache_cache]} {
        configure.ccache    ${cmake::ccache_cache}
        ui_debug "configure.ccache restored to ${cmake::ccache_cache}"
    }
    if {[info exists cmake::distcc_cache]} {
        configure.distcc    ${cmake::distcc_cache}
        ui_debug "configure.distcc restored to ${cmake::distcc_cache}"
    }
    # either compile_commands.json was created because of -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    # in which case touch'ing it won't change anything. Or else it wasn't created, in which case
    # we'll create a file that corresponds, i.e. containing an empty json array.
    if {![file exists ${build.dir}/compile_commands.json]} {
        if {![catch {set fd [open "${build.dir}/compile_commands.json" "w"]} err]} {
            puts ${fd} "\[\n\]"
            close ${fd}
        }
    }
}

# add MACPORTS_KEEP_BUILDING to the extra_env in $prefix/etc/macports/macports.conf
# and set this env. variable to a non-zero value to let the build step keep going
# as far as possible when errors occur. This can be useful to get an overview of
# all build errors in a single pass (and get the build as far as possible while you
# do something more interesting elsewhere).
if {[info exist ::env(MACPORTS_KEEP_BUILDING)] && $::env(MACPORTS_KEEP_BUILDING)} {
    build.post_args-append  -k
}

proc cmake.save_configure_cmd {{save_log_too ""}} {
    namespace upvar ::cmake configure_cmd_saved statevar
    if {[tbool statevar]} {
        ui_debug "cmake.save_configure_cmd already called"
        return;
    }
    set statevar yes

    if {${save_log_too} ne ""} {
        pre-configure {
            configure.pre_args-prepend "-cf '${configure.cmd} "
            configure.post_args-append "|& tee ${workpath}/.macports.${subport}.configure.log'"
            configure.cmd "/bin/csh"
            ui_debug "configure command set to `${configure.cmd} ${configure.pre_args} ${configure.args} ${configure.post_args}`"
        }
    }
    post-configure {
        if {![catch {set fd [open "${workpath}/.macports.${subport}.configure.cmd" "w"]} err]} {
            foreach var [array names ::env] {
                puts ${fd} "${var}=$::env(${var})"
            }
            puts ${fd} "[join [lrange [split ${configure.env} " "] 0 end] "\n"]"
            # the following variables are no longer set in the environment at this point:
            puts ${fd} "CPP=\"${configure.cpp}\""
            # these are particularly relevant because referenced in the configure.pre_args:
            puts ${fd} "CC=\"${configure.cc}\""
            puts ${fd} "CXX=\"${configure.cxx}\""
            if {${configure.objcxx} ne ${configure.cxx}} {
                puts ${fd} "OBJCXX=\"${configure.objcxx}\""
            }
            puts ${fd} "CFLAGS=\"${configure.cflags}\""
            puts ${fd} "CXXFLAGS=\"${configure.cxxflags}\""
            if {${configure.objcflags} ne ${configure.cflags}} {
                puts ${fd} "OBJCFLAGS=\"${configure.objcflags}\""
            }
            if {${configure.objcxxflags} ne ${configure.cxxflags}} {
                puts ${fd} "OBJCXXFLAGS=\"${configure.objcxxflags}\""
            }
            puts ${fd} "LDFLAGS=\"${configure.ldflags}\""
            puts ${fd} "# Commandline configure options:"
            if {${configure.optflags} ne ""} {
                puts -nonewline ${fd} " configure.optflags=\"${configure.optflags}\""
            }
            if {${configure.compiler} ne ""} {
                puts -nonewline ${fd} " configure.compiler=\"${configure.compiler}\""
            }
            if {${configure.cxx_stdlib} ne ""} {
                puts -nonewline ${fd} " configure.cxx_stdlib=\"${configure.cxx_stdlib}\""
            }
            if {${configureccache} ne ""} {
                puts -nonewline ${fd} " configureccache=\"${configureccache}\""
            }
            puts ${fd} ""
            puts ${fd} "\ncd ${worksrcpath}"
            puts ${fd} "${configure.cmd} [join ${configure.pre_args}] [join ${configure.args}] [join ${configure.post_args}]"
            close ${fd}
            unset fd
        }
        if {[file exists ${build.dir}/CMakeCache.txt]} {
            # keep a backup of the CMake cache file
            file copy -force ${build.dir}/CMakeCache.txt ${build.dir}/CMakeCache-MacPorts.txt
        }
    }
}

platform darwin {
    set cmake._archflag_vars {cc_archflags cxx_archflags ld_archflags objc_archflags objcxx_archflags \
        universal_cflags universal_cxxflags universal_ldflags universal_objcflags universal_objcxxflags}
    pre-configure {
        # cmake will add the correct -arch flag(s) based on the value of CMAKE_OSX_ARCHITECTURES.
        if {[variant_exists universal] && [variant_isset universal]} {
            if {[info exists universal_archs_supported]} {
                merger_arch_compiler no
                merger_arch_flag no
                if {${cmake.set_osx_architectures}} {
                    global merger_configure_args
                    foreach arch ${universal_archs_to_use} {
                        lappend merger_configure_args(${arch}) -DCMAKE_OSX_ARCHITECTURES=${arch}
                    }
                }
            } elseif {${cmake.set_osx_architectures}} {
                configure.universal_args-append \
                    -DCMAKE_OSX_ARCHITECTURES="[join ${configure.universal_archs} \;]"
            }
        } elseif {${cmake.set_osx_architectures}} {
            configure.args-append \
                -DCMAKE_OSX_ARCHITECTURES="${configure.build_arch}"
        }

        # Setting our own -arch flags is unnecessary (in the case of a non-universal build) or even
        # harmful (in the case of a universal build, because it causes the compiler identification to
        # fail; see https://public.kitware.com/pipermail/cmake-developers/2015-September/026586.html).
        # Save all archflag-containing variables before changing any of them, because some of them
        # declare their default value based on the value of another.
        foreach archflag_var ${cmake._archflag_vars} {
            global cmake._saved_${archflag_var}
            set cmake._saved_${archflag_var} [option configure.${archflag_var}]
        }
        foreach archflag_var ${cmake._archflag_vars} {
            configure.${archflag_var}
        }

        configure.args-append -DCMAKE_OSX_DEPLOYMENT_TARGET="${macosx_deployment_target}"

        if {${configure.sdkroot} != ""} {
            configure.args-append -DCMAKE_OSX_SYSROOT="${configure.sdkroot}"
        } else {
            configure.args-append -DCMAKE_OSX_SYSROOT="/"
        }
    }
    post-configure {
        # Although cmake wants us not to set -arch flags ourselves when we run cmake,
        # ports might have need to access these variables at other times.
        foreach archflag_var ${cmake._archflag_vars} {
            global cmake._saved_${archflag_var}
            # avoid overquoting by adding each list element individually
            configure.${archflag_var} {*}[set cmake._saved_${archflag_var}]
        }
    }
}

configure.universal_args-delete --disable-dependency-tracking

variant debug description "Enable debug binaries" {
    if {![info exists cmake.debugopts]} {
        # this PortGroup uses a custom CMAKE_BUILD_TYPE giving complete control over
        # the compiler flags. We use that here: replace the default -O2 or -Os with -O0, add
        # debugging options and do otherwise an exactly identical build.
        configure.cflags-replace         -O2 -O0
        configure.cxxflags-replace       -O2 -O0
        configure.objcflags-replace      -O2 -O0
        configure.objcxxflags-replace    -O2 -O0
        configure.ldflags-replace        -O2 -O0
        configure.cflags-replace         -Os -O0
        configure.cxxflags-replace       -Os -O0
        configure.objcflags-replace      -Os -O0
        configure.objcxxflags-replace    -Os -O0
        configure.ldflags-replace        -Os -O0
        # get most if not all possible debug info
        if {[string match *clang* ${configure.cxx}] || [string match *clang* ${configure.cc}]} {
            set cmake.debugopts "-g -fno-limit-debug-info -fstandalone-debug -DDEBUG"
        } else {
            set cmake.debugopts "-g -DDEBUG"
        }
    } else {
        ui_debug "+debug variant uses custom cmake.debugopts \"${cmake.debugopts}\""
    }
    configure.cflags-append         ${cmake.debugopts}
    configure.cxxflags-append       ${cmake.debugopts}
    configure.objcflags-append      ${cmake.debugopts}
    configure.objcxxflags-append    ${cmake.debugopts}
    configure.ldflags-append        ${cmake.debugopts}
    # try to ensure that info won't get stripped
    configure.args-append           -DCMAKE_STRIP:FILEPATH=/bin/echo
}
