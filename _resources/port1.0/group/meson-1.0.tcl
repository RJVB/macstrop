# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4

# This PortGroup supports the meson build system
#
# Usage:
#
# PortGroup meson 1.0
#

PortGroup                   save_configure_cmd 1.0

# Wrap mode handling for subprojects.
# Possible values: default, nofallback, nodownload, forcefallback, nopromote
options meson.wrap_mode
default meson.wrap_mode     {default}

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
default configure.pre_args  {setup --prefix=${prefix} -Db_colorout=never}
default configure.post_args {[meson::get_post_args]}
configure.universal_args-delete \
                            --disable-dependency-tracking

default build.dir           {[meson::build.dir]}
default build.cmd           {${prefix}/bin/ninja}
default build.post_args     {-v}
default build.target        ""

# remove DESTDIR= from arguments, but rather take it from environmental variable
destroot.env-append         DESTDIR=${destroot}
# default destroot.cmd        {${prefix}/bin/meson}
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
            return "${configure.dir} ${build.dir} --cross-file=[option muniversal.build_arch]-darwin --wrap-mode=[option meson.wrap_mode]"
        } else {
            return "${configure.dir} ${build.dir} --wrap-mode=[option meson.wrap_mode]"
        }
    } elseif {[info exists muniversal.current_arch]} {
        # muniversal 1.0 PG is being used
        return "${configure.dir} ${build_dir}-${muniversal.current_arch} --cross-file=${muniversal.current_arch}-darwin --wrap-mode=[option meson.wrap_mode]"
    } else {
        return "${configure.dir} ${build_dir} --wrap-mode=[option meson.wrap_mode]"
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
        ui_debug "Found -Ofast or -O3 in compiler flags -> meson optim level 3"
        configure.pre_args-append -Doptimization=3
    } elseif {[string match *-O2* "${configure.cflags} ${configure.cxxflags} ${configure.optflags}"]} {
        ui_debug "Found -O2 in compiler flags -> meson optim level 2"
        configure.pre_args-append -Doptimization=2
    } elseif {[string match *-Os* "${configure.cflags} ${configure.cxxflags} ${configure.optflags}"]} {
        ui_debug "Found -Os in compiler flags -> meson optim level s"
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
        set flags "[join [split ${configure.cflags}]] [join [split ${configure.cppflags}]]"
        configure.pre_args-append \
                            "-Dc_args=\"${flags}\""
        set flags "[join [split ${configure.cxxflags}]] [join [split ${configure.cppflags}]]"
        configure.pre_args-append \
                            "-Dcpp_args=\"${flags}\""
        set flags "[join [split ${configure.objcflags}]] [join [split ${configure.cppflags}]]"
        configure.pre_args-append \
                            "-Dobjc_args=\"${flags}\""
        set flags "[join [split ${configure.objcxxflags}]] [join [split ${configure.cppflags}]]"
        configure.pre_args-append \
                            "-Dobjcpp_args=\"${flags}\"" \
                            "-Dcpp_link_args=\"[join [split ${configure.ldflags}]]\""
    }
}

proc meson.save_configure_cmd {{save_log_too ""}} {
    namespace upvar ::meson configure_cmd_saved statevar
    global merger_combine merger_arch_flag
    if {[tbool statevar]} {
        ui_debug "meson.save_configure_cmd already called"
        return;
    }
    set statevar yes
    # no-one should call configure.save_configure_cmd either!
    set configure::statevar yes

    if {![info exists configure.args]} {
        configure.args-append
    }
    configure::initialise_save_logic "${save_log_too}"
    post-configure {
        configure::write_configure_cmd "${workpath}/.macports.${subport}.configure.cmd"
        configure::try_copy_configure_log "${workpath}/.macports.${subport}.configure.log"
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
