# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4

# This portgroup provides evolving support on Linux for dealing with the dual ABI that libstdc++ has
# provided since GCC 5.x, and which hasn't always been enabled by all distributions. For instance,
# Ubuntu 14.04 have kept it disabled even in the GCC 9.4 compiler and runtimes they provided, which
# means that even clang would build code using the old ABI only by default.
# This is fine as long as no GCC builds from MacPorts are used - or if they too are configured to
# disable the new ABI by default.
# Even if not there are few problems because the libstdc++ provided through port:libgcc will contain
# the implementations of both ABIs but in rare cases a C++-based library will lock in the choice and
# provide its own ABI based on either the old or the new libstdc++ ABI. port:astyle is an example;
# if built with the new libstdc++ ABI it will require that same choice from its dependents.
#
# The fine print: https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_dual_abi.html .

platform linux {

    namespace eval stdcxxabi {
        # our directory:
        set currentportgroupdir [file dirname [dict get [info frame 0] file]]
        # ports may (have to) include us more than once
        if {![info exists includecounter]} {
            set includecounter  0
        }
    }

    if {${stdcxxabi::includecounter} == 0} {
        if {![info exists compilers.variants]} {
            PortGroup compilers 1.0
        }
        if {[info proc require_active_variants] ne "require_active_variants"} {
            PortGroup active_variants 1.1
        }

        options stdcxxabi.dependencies_concerned_by_ABI
        default stdcxxabi.dependencies_concerned_by_ABI {}

        proc stdcxxabi::getABISetter {CXX {args {}}} {
            ui_debug "Determining C++ ABI used by ${CXX} ${args}"
            if {${args} ne {}} {
                set cmd "${CXX} ${args} -x c++ -CC -dD -E -o - -"
            } else {
                set cmd "${CXX} -x c++ -CC -dD -E -o - -"
            }
            set ret [exec echo "#include <cstddef>" | {*}${cmd} \
                | grep "_GLIBCXX_USE_CXX11_ABI.*\[01\]" | sed -e "s/#define/set/g"]
            if {${ret} eq ""} {
                ui_debug "_GLIBCXX_USE_CXX11_ABI is not defined, assuming ancient libstdc++ evidently using the old ABI"
                return "set _GLIBCXX_USE_CXX11_ABI 0"
            } else {
                return ${ret}
            }
        }

        # check how the system GCC c++ compiler is configured w.r.t. the CXX11 ABI
        # and set up this port so that by default it will build code that should
        # link against binaries generated against the system libstdc++ runtime (= with
        # the system compilers or our own macports-clang compilers NOT invoked with
        # -stdlib=macports-libstdc++).
        namespace eval stdcxxabi {
            if {[catch {eval [getABISetter /usr/bin/g++]} err]} {
                ui_debug "Failed to determine the libstdc++ ABI in use: ${err}"
                ui_debug "Assuming a modern system that doesn't disable the dual ABI"
                set _GLIBCXX_USE_CXX11_ABI 1
            }
        }

        variant oldabi description {The old libstdc++ ABI will be used by default (#define _GLIBCXX_USE_CXX11_ABI 0)} {}
        if {![info exists stdcxxabi.is_gcc_internal]} {
            if {!${stdcxxabi::_GLIBCXX_USE_CXX11_ABI}} {
                default_variants +oldabi
                if {![variant_isset oldabi]} {
                    ui_warn "variant `oldabi` unset; code generated against port:${subport} can fail to link with binaries generated against the system C++ runtime!"
                    notes-append "\nvariant `oldabi` is unset; code generated against port:${subport} can fail to link with binaries generated against the system C++ runtime!"
                }
            }
            if {[string match macports-gcc* ${configure.compiler}]
                    || ${configure.cxx_stdlib} eq "libstdc++_macports"
                    || ${configure.cxx_stdlib} eq "macports-libstdc++"} {
                depends_lib-append port:libgcc
                stdcxxabi.dependencies_concerned_by_ABI-append port:libgcc
            }
        }

        proc stdcxxabi::callback {} {
            global stdcxxabi.dependencies_concerned_by_ABI
            foreach d ${stdcxxabi.dependencies_concerned_by_ABI} {
                if {[variant_isset oldabi]} {
                    ui_debug "Requiring old stdc++ ABI (+oldabi) on ${d}"
                    require_active_variants ${d} oldabi
                } else {
                    ui_debug "Requiring new stdc++ ABI (-oldabi) on ${d}"
                    require_active_variants ${d} {} oldabi
                }
            }
        }
        port::register_callback stdcxxabi::callback
    }

}

# kate: backspace-indents true; indent-pasted-text true; indent-width 4; keep-extra-spaces true; remove-trailing-spaces modified; replace-tabs true; replace-tabs-save true; syntax Tcl/Tk; tab-indents true; tab-width 4;
