# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4

# This PortGroup supports the meson build system
#
# Usage:
#
# PortGroup meson 1.0
#

#---------
# WARNING:
#---------
#
# Meson's install_name currently seems to be broken, so workarounds might be needed to make ports actually work.
# See: https://github.com/mesonbuild/meson/issues/2121


# meson builds need to be done out-of-source
default build_dir           {${workpath}/build}
default source_dir          {${worksrcpath}}

namespace eval meson {
    proc build.dir {} {
#         global muniversal.current_arch
#         if {[info exists muniversal.current_arch]} {
#             ui_info "build.dir -> [option build_dir]-${muniversal.current_arch}"
#             return "[option build_dir]-${muniversal.current_arch}"
#         } else {
            return "[option build_dir]"
#         }
    }

#     proc get_post_args {} {
#         global source_dir
#         return "${source_dir} ."
#     }
}

depends_build-append        port:meson \
                            port:ninja
depends_skip_archcheck-append \
                            meson \
                            ninja

# TODO: --buildtype=plain tells Meson not to add its own flags to the command line. This gives the packager total control on used flags.
default configure.cmd       {${prefix}/bin/meson}
default configure.post_args {[list [option source_dir] "."]}
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

pre-configure {
    if {[file exists ${build.dir}/meson-private]} {
        configure.pre_args-append \
                            --reconfigure
    }
    configure.pre_args-append \
                            --buildtype=custom
}

proc meson.save_configure_cmd {{save_log_too ""}} {
    namespace upvar ::meson configure_cmd_saved statevar
    if {[tbool statevar]} {
        ui_debug "meson.save_configure_cmd already called"
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
    }
}

