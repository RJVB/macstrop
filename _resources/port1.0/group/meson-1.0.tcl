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
    if {[file exists ${build.dir}/compile_commands.json]} {
        configure.pre_args-append \
                            --reconfigure
    }
    configure.pre_args-append \
                            --buildtype=custom
}
