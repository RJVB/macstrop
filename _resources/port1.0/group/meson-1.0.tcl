# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4

# This PortGroup supports the meson build system
#
# Usage:
#
# PortGroup meson 1.0
#


# meson builds need to be done out-of-source
default build_dir           {${workpath}/build}
default source_dir          {${worksrcpath}}

options meson.build_type
default meson.build_type    plain

options meson.debugopts
# Set meson.debugopts to the desired compiler debug options (or an empty string) if you want to
# use custom options with the +debug variant.
default meson.debugopts     {[meson::debugopts]}

namespace eval meson {
    proc build.dir {} {
        return "[option build_dir]"
    }

}

depends_skip_archcheck-append \
                            meson \
                            ninja

# TODO: --buildtype=plain tells Meson not to add its own flags to the command line. This gives the packager total control on used flags.
default configure.cmd       {${prefix}/bin/meson}
default configure.pre_args  {setup --prefix=${prefix}}
default configure.post_args {[list [option source_dir] "."]}
# from mcalhoun's commit to make this PG compatible with muniversal:
## DO WE NEED THIS?! (or is using `source_dir` good enough?)
# default configure.post_args {[meson::get_post_args]}
configure.universal_args-delete \
                            --disable-dependency-tracking

default configure.dir       {[meson::build.dir]}
default build.dir           {${configure.dir}}
default build.cmd           {${prefix}/bin/ninja}
default build.post_args     {-v}
default build.target        ""

# remove DESTDIR= from arguments, but rather take it from environmental variable
destroot.env-append         DESTDIR=${destroot}
default destroot.post_args  ""
if {![info exists python.default_version]} {
    destroot.pre_args-prepend -v
}

# meson checks LDFLAGS during install to respect rpaths set via that variable
# for safety, add LDFLAGS to both build and destroot environments
pre-build {
    build.env-append        "LDFLAGS=${configure.ldflags}"
}
pre-destroot {
    destroot.env-append     "LDFLAGS=${configure.ldflags}"
}

namespace eval meson { }

proc meson::get_post_args {} {
    global configure.dir build_dir build.dir muniversal.current_arch muniversal.build_arch
    if {[info exists muniversal.build_arch]} {
        # muniversal 1.1 PG is being used
        if {[option muniversal.is_cross.[option muniversal.build_arch]]} {
            return "${configure.dir} ${build.dir} --cross-file=[option muniversal.build_arch]-darwin"
        } else {
            return "${configure.dir} ${build.dir}"
        }
    } elseif {[info exists muniversal.current_arch]} {
        # muniversal 1.0 PG is being used
        return "${configure.dir} ${build_dir}-${muniversal.current_arch} --cross-file=${muniversal.current_arch}-darwin"
    } else {
        return "${configure.dir} ${build_dir}"
    }
}

proc meson::debugopts {} {
    global configure.cxx configure.cc
    # get most if not all possible debug info
    if {[string match *clang* ${configure.cxx}] || [string match *clang* ${configure.cc}]} {
        return "-g -fno-limit-debug-info -fstandalone-debug"
    } else {
        return "-g -DDEBUG"
    }
}

proc meson::add_depends {} {
    depends_build-append    port:meson \
                            path:bin/ninja:ninja
}

platform linux {
    # many ports are misbehaved and reset configure.args, so use pre_args to
    # ensure libraries go where we want them to:
    configure.pre_args-append --libdir ${prefix}/lib
}

pre-configure {
    if {[file exists ${build.dir}/meson-private/cmd_line.txt]} {
        # only request a reconfigure after a successful previous
        # configure run; only then will the cmd_line.txt file be present.
        configure.pre_args-append \
                            --reconfigure
    }
    # set a reasonable value for the requested optimisation level:
    if {[string match *-Ofast* "${configure.cflags} ${configure.cxxflags} ${configure.optflags}"]
        || [string match *-O3* "${configure.cflags} ${configure.cxxflags} ${configure.optflags}"]} {
        configure.pre_args-append -Doptimization=3
    } elseif {[string match *-O2* "${configure.cflags} ${configure.cxxflags} ${configure.optflags}"]} {
        configure.pre_args-append -Doptimization=2
    } elseif {[string match *-O2* "${configure.cflags} ${configure.cxxflags} ${configure.optflags}"]} {
        configure.pre_args-append -Doptimization=s
    }
    # override the optimisation setting by setting the build type to plain (not custom). Not using the override
    # approach means meson will second-guess the buildtype regardless of what we asked for (there's
    # no guarantee it won't ever if we do use the override trick).
    configure.pre_args-append \
                            --buildtype ${meson.build_type}
    # the proper way to pass compiler/linker arguments, which we prefer not to use
    # in universal mode as it is not (?!) possible to know what arch we're building
    # for here in a pre-configure block.
    if {!${universal_possible} || ![variant_isset universal]} {
        configure.pre_args-append \
                            "-Dc_args=\"[join [split ${configure.cflags}] ,]\"" \
                            "-Dcpp_args=\"[join [split ${configure.cxxflags}] ,]\"" \
                            "-Dobjc_args=\"[join [split ${configure.objcflags}] ,]\"" \
                            "-Dobjcpp_args=\"[join [split ${configure.objcxxflags}] ,]\"" \
                            "-Dc_link_args=\"[join [split ${configure.ldflags}] ,]\"" \
                            "-Dcpp_link_args=\"[join [split ${configure.ldflags}] ,]\""
    }
}

proc meson.save_configure_cmd {{save_log_too ""}} {
    namespace upvar ::meson configure_cmd_saved statevar
    if {[tbool statevar]} {
        ui_debug "meson.save_configure_cmd already called"
        return;
    }
    set statevar yes

    if {![info exists configure.args]} {
        configure.args-append
    }
    if {${save_log_too} ne ""} {
        pre-configure {
            configure.pre_args-prepend "-cf '${configure.cmd} "
            configure.post_args-append "|& tee ${workpath}/.macports.${subport}.configure.log'"
            configure.cmd "/bin/csh"
            ui_debug "configure command set to `${configure.cmd} ${configure.pre_args} ${configure.args} ${configure.post_args}`"
        }
        if {${save_log_too} eq "install log"} {
            post-destroot {
                set docdir ${destroot}${prefix}/share/doc/${subport}
                xinstall -m 755 -d ${docdir}
                foreach cfile [glob -nocomplain ${workpath}/.macports.${subport}.configure*] {
                    xinstall -m 644 ${cfile} ${docdir}/[string map {".macports" "macports"} [file tail ${cfile}]]
                }
            }
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
    }
}

variant debug description "Enable debug binaries" {
    default meson.build_type            debug
    pre-configure {
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

        if {${meson.debugopts} ne [meson::debugopts]} {
            ui_debug "+debug variant uses custom meson.debugopts=\"${meson.debugopts}\""
        } else {
            ui_debug "+debug variant uses default meson.debugopts=\"${meson.debugopts}\""
        }
        configure.cflags-append         ${meson.debugopts}
        configure.cxxflags-append       ${meson.debugopts}
        configure.objcflags-append      ${meson.debugopts}
        configure.objcxxflags-append    ${meson.debugopts}
        configure.ldflags-append        ${meson.debugopts}
    }
}
port::register_callback meson::add_depends
