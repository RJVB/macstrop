# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4
#
# Copyright (c) 2023 R.J.V. Bertin
# All rights reserved.
#
# Usage:
# PortGroup     rustup 1.1
#
# This PortGroup is for ports that require rust and/or cargo to be built
# but do not depend on it otherwise (port:clamav, for example). Rather than
# requiring the obligatory installation of port:rust and/or port:cargo,
# allow the port to use a temporary, private install from rustup.rs .
#
# In case port:rust and port:cargo are installed and active those are felt
# back on to prevent the overhead of downloading and installing a temp.
# rust installation but the build will still do a traditional cargo build
# that fetches its own copies of the required packages (crates) itself.
# The configure phase is also NOT disabled but is used instead to provide
# some config information and optionally to update the cargo.lock file so
# dependencies are bumped to their latest versions. This requires a rustup
# build (+rustup_build) and unsetting configure.pre_args .
#
# This PG can also be used because another type of build system (e.g. cmake)
# requires the presence of rustc. In this case the build system should not
# be redefined: set rustup.disable_cargo to "true" before including us.

if {${os.platform} eq "darwin"} {
    set LTO.allow_ThinLTO no
} else {
    # linking is done by invoking the actual linker (ld) so we cannot
    # know (easily enough) how to enable LTO, what plugin to invoke
    # to read the compiled object files etc. Even when `cc` is used
    # (as when in port:clamav) there will be errors about "unknown print
    # print request `-split-debuginfo` which I yet have to avoid. Bummer...
    set LTO.disable_LTO yes
}
PortGroup LTO 1.0

if {${os.platform} eq "darwin"} {
    if {${os.major} < 16} {
        PortGroup legacysupport 1.1
    } else {
        set legacysupport.newest_darwin_requires_legacy 16
    }
}

namespace eval rustup {
    # our directory:
    set currentportgroupdir [file dirname [dict get [info frame 0] file]]
    # ports may (have to) include us more than once
    if {![info exists includecounter]} {
        set includecounter  0
    }

    if {${includecounter} >= 1} {
        ui_debug "We don't include PG rustup more than once"
        return
    }

    set setup_build {}
}

namespace eval rustup {
    proc use_rustup {} {
        return [expr [variant_exists rustup_build] && [variant_isset rustup_build]]
    }

    proc set_use_configure {{arg {}}} {
        global use_configure
        if {${arg} ne {}} {
            ui_debug "rustup::set_use_configure ${arg}"
            use_configure ${arg}
        }
        if {[tbool use_configure]} {
            ui_debug "Doing rustup::setup_build in pre-configure"
            set rustup::setup_build pre-configure
        } else {
            ui_debug "Doing rustup::setup_build in pre-build"
            set rustup::setup_build pre-build
        }
    }

    variant rustup_build conflicts no_rustup description {build this port using a private rust install from rustup.rs} {}
    if {![variant_isset no_rustup] && \
            !([file exists ${prefix}/bin/rustc] && [file exists ${prefix}/bin/cargo])} {
        default_variants-append +rustup_build
        if {[variant_isset rustup_build]} {
            ui_debug "Build will use rustup by default"
        }
    }

    # The path where we install rustup.
    # NB NB: we need to access this variable via its namespace in
    # the post-X blocks below because they are not executed inside
    # our own namespace!
    set home    ${workpath}/.rustup

#     options rustup.force_cargo_update
#     default rustup.force_cargo_update   no

    if {[rustup::use_rustup]} {
        post-fetch {
            if {${subport} ne "rustup"} {
                xinstall -d ${rustup::home}/Cargo/bin
                if {[file exists ${prefix}/bin/rustup]} {
                    xinstall ${prefix}/bin/rustup ${rustup::home}/Cargo/bin/rustup-init
                }
            } elseif {![file exists ${rustup::home}/rustup-install.sh]} {
                xinstall -d ${rustup::home}
                if {${os.platform} eq "darwin"} {
                    if {${os.major} < ${legacysupport.newest_darwin_requires_legacy}} {
                        #set rinit "https://static.rust-lang.org/rustup/dist/${build_arch}-apple-darwin/rustup-init"
                        set rinit "https://static.rust-lang.org/rustup/archive/1.26.0/${build_arch}-apple-darwin/rustup-init"
                        ui_msg "Downloading the rustup installer binary directly from ${rinit}"
                        xinstall -d ${rustup::home}/Cargo/bin/
                        curl fetch --progress ui_progress_download \
                            ${rinit} \
                            ${rustup::home}/Cargo/bin/rustup-init
                        legacysupport::relink_libSystem ${rustup::home}/Cargo/bin/rustup-init
                        file attributes ${rustup::home}/Cargo/bin/rustup-init -permissions ugo+x
                    }
                } elseif {${os.platform} eq "linux"} {
                    # the script downloads the rustup-init binary and installs it as
                    # $CARGO_HOME/bin/rustup ; on my Linux this can generate an EAGAIN
                    # error, apparently because I'm running a ZFS version that doesn't
                    # work nicely with copy_file_range(2). So, we download that
                    # binary ourselves...
                    ui_debug "Downloading the rustup installer binary directly"
                    xinstall -d ${rustup::home}/Cargo/bin/
                    curl fetch --progress ui_progress_download \
                        https://static.rust-lang.org/rustup/dist/[exec uname -m]-unknown-linux-gnu/rustup-init \
                        ${rustup::home}/Cargo/bin/rustup-init
                    file attributes ${rustup::home}/Cargo/bin/rustup-init -permissions ugo+x
                }
                if {![file exists ${rustup::home}/Cargo/bin/rustup-init]} {
                    curl fetch --remote-time --progress ui_progress_download \
                        https://sh.rustup.rs \
                        ${rustup::home}/rustup-install.sh
                    platform darwin {
                        reinplace "s|mktemp|gmktemp|g" ${rustup::home}/rustup-install.sh
                    }
                    file attributes ${rustup::home}/rustup-install.sh -permissions ug+x
                }
            }
        }
    }

    pre-extract {
        if {[rustup::use_rustup]} {
            set env(RUSTUP_INIT_SKIP_PATH_CHECK) yes
            if {![file exists ${rustup::home}/Cargo/bin/cargo]} {
                ui_msg "--->  Doing rustup install"
                set deftoolchain ""
                if {${os.platform} eq "darwin" && ${os.major} < ${legacysupport.newest_darwin_requires_legacy}} {
                    ui_warn "     NB: you may get a notification of a rustc crash at the end of the install: you can ignore this"
                    set env(RUSTUP_INIT_SKIP_PATH_CHECK) yes
                    set env(RUSTUP_DONT_CALL_RUSTC) yes
                    set deftoolchain "--default-toolchain none"
                }
                if {[file exists ${rustup::home}/Cargo/bin/rustup-init]} {
                    platform darwin {
                        # now make certain we use an up-to-date libcurl, or else download failures may occur
                        # (the first replace is superfluous if we're using port:rustup)
                        system "install_name_tool -change /usr/lib/libcurl.4.dylib ${prefix}/lib/libcurl.4.dylib ${rustup::home}/Cargo/bin/rustup-init"
                    }
                    system "${rustup::home}/Cargo/bin/rustup-init --profile minimal --no-modify-path ${deftoolchain} -y -q"
                } else {
                    if {${os.platform} eq "darwin" && ${os.major} < ${legacysupport.newest_darwin_requires_legacy}} {
                        ui_warn "--->    downloading the older rustup 1.26.0"
                        set env(RUSTUP_UPDATE_ROOT) "https://static.rust-lang.org/rustup/archive/1.26.0"
                    }
                    system "${rustup::home}/rustup-install.sh --profile minimal --no-modify-path ${deftoolchain} -y -q"
                }
                platform darwin {
                    if {${os.platform} eq "darwin" && ${os.major} < ${legacysupport.newest_darwin_requires_legacy}} {
                        if {[catch {exec nm -U ${prefix}/lib/libMacportsLegacySupport.dylib | fgrep -q clonefile} err result]} {
                            ui_debug "port:legacy-support does NOT provide the clonefile functions; installing the stable rust toolchain"
                            set toolchain_version 1.80.1
                        } else {
                            ui_debug "port:legacy-support provides the clonefile functions; installing the stable rust toolchain"
                            # as of 250328, that is Rust 1.85.1 (250315).
                            # as of 250408, that is Rust 1.86.0 (250331).
                            set toolchain_version stable
                        }
                        system "${rustup::home}/Cargo/bin/rustup install --profile minimal --no-self-update ${toolchain_version}"
                        system "${rustup::home}/Cargo/bin/rustup default ${toolchain_version}"
                    } else {
                        set toolchain_version stable
                    }
                    # ${rustup::home}/Cargo/bin is populated with hardlinks, so we only need to
                    # fix up a single downloaded for for running on legacy systems
                    # NB NB: for this to work legacysupport.newest_darwin_requires_legacy must be >= 16
                    system "install_name_tool -change /usr/lib/libcurl.4.dylib ${prefix}/lib/libcurl.4.dylib ${rustup::home}/Cargo/bin/cargo"
                    legacysupport::relink_libSystem ${rustup::home}/Cargo/bin/cargo
                    foreach c [glob ${rustup::home}/toolchains/${toolchain_version}-*-apple-darwin/bin/cargo] {
                        system "install_name_tool -change /usr/lib/libcurl.4.dylib ${prefix}/lib/libcurl.4.dylib ${c}"
                        legacysupport::relink_libSystem ${c}
                    }
                    foreach d {rustc rustdoc} {
                        foreach c [glob ${rustup::home}/toolchains/${toolchain_version}-*-apple-darwin/bin/${d}] {
                            legacysupport::relink_libSystem ${c}
                        }
                    }
                    foreach c [glob ${rustup::home}/toolchains/${toolchain_version}-*-apple-darwin/lib/*.dylib] {
                        legacysupport::relink_libSystem ${c}
                    }
                    if {${os.major} < ${legacysupport.newest_darwin_requires_legacy}} {
                        ui_msg "     rustup install completed."
                    }
                }
            }
            file delete -force ${rustup::home}/Cargo/bin/rustup-init
            if {[file exists ${prefix}/bin/cargo-cache-autoclean]} {
                ln -sf ${prefix}/bin/cargo-cache-autoclean ${rustup::home}/Cargo/bin/
            }
        }
#         platform linux {
#             # rust builds can link libgcc_s explicitly but there isn't always a libgcc_s.so on the linker path
#             # so we have to provide one - ${rustup::home}/lib was already added to the wrapper script.
#             ui_msg [glob -nocomplain /usr/lib/libgcc_s.so /usr/*-linux-*/libgcc_s.so /lib/libgcc_s.so \
#                                 /lib/*-linux-*/libgcc_s.so]
#             if {[glob -nocomplain /usr/lib/libgcc_s.so /usr/*-linux-*/libgcc_s.so /lib/libgcc_s.so \
#                     /lib/*-linux-*/libgcc_s.so] eq {}} {
#                 xinstall -d ${rustup::home}/lib
#                 foreach l [glob -nocomplain /usr/lib/libgcc_s.so.1 /usr/*-linux-*/libgcc_s.so.1 /lib/libgcc_s.so.1 \
#                 /lib/*-linux-*/libgcc_s.so.1] {
#                     ln -sf ${l} ${rustup::home}/lib/libgcc_s.so
#                 }
#             }
#         }
    }

    proc ccache-wrapper {pth comm} {
        if {![catch {set f [open "${pth}" "w"]} err]} {
            puts ${f} "#!/bin/sh\n"
            puts ${f} "exec ccache ${comm} \"$@\""
            close ${f}
            file attributes ${pth} -permissions ug+x
        } else {
            ui_error $::errorInfo
            return -code error "failed to create ccache wrapper ${pth} for ${comm}: ${err}"
        }
    }

    # rustup::set_use_configure ${use_configure}
    if {[tbool use_configure]} {
        ui_debug "Doing rustup::setup_build in pre-configure"
        set rustup::setup_build pre-configure
    } else {
        ui_debug "Doing rustup::setup_build in pre-build"
        set rustup::setup_build pre-build
    }
    ${rustup::setup_build} {
        ui_debug "PATH=$env(PATH)"
        catch {system -W ${worksrcpath} "${rustup::home}/Cargo/bin/cargo-cache-autoclean"}
        if {![rustup::use_rustup]} {
            ui_debug "Setting up regular port:cargo + port:rust  build"
            xinstall -m 755 -d ${rustup::home}/Cargo/bin/
        } else {
            ui_debug "Setting up rustup build"
            xinstall -m 755 -d ${cargo.home}
            if {[file exists ${cargo.home}/config.toml]} {
                ui_warn "replacing existing ${cargo.home}/config.toml"
                ui_debug "config.toml contents:"
                ui_debug ">>> [exec cat ${cargo.home}/config.toml] <<<"
            }
            set conf [open "${cargo.home}/config.toml" "w"]

            puts $conf "\[build\]"
            puts -nonewline $conf "rustflags = \[\"--remap-path-prefix=[file normalize ${worksrcpath}]=\", \
                \"--remap-path-prefix=${cargo.home}=\", \
                \"--remap-path-prefix=$env(RUSTUP_HOME)=RUSTUP_HOME\""
            foreach la ${configure.ldflags} {
                puts -nonewline $conf ",\"-C\", \"link-arg=${la}\""
            }
            # puts -nonewline $conf ",\"-v\""
            puts $conf "\]"
            if {${os.platform} eq "darwin"} {
                # be sure to include all architectures in case, e.g., a 64-bit Cargo compiles a 32-bit port
                # note that setting the linker on linux causes weird failures even if the executed wrapper
                # script is the same...
                set has_triplets no
                foreach arch {arm64 x86_64 i386 ppc ppc64} {
                    if {[option triplet.${arch}] ne "none"} {
                        puts $conf "\[target.[option triplet.${arch}]\]"
                        puts $conf "linker = \"[compwrap::wrap_compiler ld]\""
                        set has_triplets yes
                    }
                }
#                 if {[tbool has_triplets]} {
#                     puts $conf "\[env\]"
#                     foreach arch {arm64 x86_64 i386 ppc ppc64} {
#                         if {[option triplet.${arch}] ne "none"} {
#                             if {${compwrap.ccache_supported_compilers} eq {}} {
#                                 puts $conf "CC_[option triplet.${arch}] = \{ value = \"ccache [compwrap::wrap_compiler cc]\", force = true \}"
#                                 puts $conf "CXX_[option triplet.${arch}] = \{ value = \"ccache [compwrap::wrap_compiler cxx]\", force = true \}"
#                             } else {
#                                 puts $conf "CC_[option triplet.${arch}] = \{ value = \"[compwrap::wrap_compiler cc]\", force = true \}"
#                                 puts $conf "CXX_[option triplet.${arch}] = \{ value = \"[compwrap::wrap_compiler cxx]\", force = true \}"
#                             }
#                         }
#                     }
#                 }
            }
            close $conf
            system "cat ${cargo.home}/config.toml"
        }
        file delete -force \
            ${rustup::home}/Cargo/bin/cc \
            ${rustup::home}/Cargo/bin/c++ \
            ${rustup::home}/Cargo/bin/ld
        # the cmake PG unsets configure.ccache but not configureccache; the
        # compwrap wrappers thus still need a ccache wrapper when using the upstream
        # compiler_wrapper and rust PGs which don't recognise `configureccache` and
        # undefine ccache support for all compilers
        if {${compwrap.ccache_supported_compilers} eq {}} {
            rustup::ccache-wrapper ${rustup::home}/Cargo/bin/cc \
                                                [compwrap::wrap_compiler cc]
            rustup::ccache-wrapper ${rustup::home}/Cargo/bin/c++ \
                                                [compwrap::wrap_compiler cxx]
        } else {
            ln -s [compwrap::wrap_compiler cc]  ${rustup::home}/Cargo/bin/cc
            ln -s [compwrap::wrap_compiler cxx] ${rustup::home}/Cargo/bin/c++
        }
        ln -s [compwrap::wrap_compiler ld]      ${rustup::home}/Cargo/bin/ld
    }

    pre-build {
        ui_debug "PATH=$env(PATH)"
    }
    post-build {
        catch {system -W ${worksrcpath} "${rustup::home}/Cargo/bin/cargo-cache-autoclean"}
    }
}

#############################################################################
# global namespace code
#############################################################################

# do configure.ld checking here
if {![info exists configure.ld]} {
    options configure.ld
}
if {${os.platform} eq "darwin"} {
    default configure.ld            ${configure.cc}
} else {
    default configure.ld            ${prefix}/bin/ld
    depends_build-append            port:binutils \
                                    port:wrapped-syscalls
    if {[info exists env(LD_PRELOAD)]} {
        set env(LD_PRELOAD)         "${prefix}/lib/libwrapped_syscalls.so:$env(LD_PRELOAD)"
    } else {
        set env(LD_PRELOAD)         "${prefix}/lib/libwrapped_syscalls.so"
    }
    extract.env-append              COPY_FILE_RANGE_VERBOSE=1 RENAME_VERBOSE=1 RENAME_ACROSS_DEVICES=1
    configure.env-append            COPY_FILE_RANGE_VERBOSE=1 RENAME_VERBOSE=1 RENAME_ACROSS_DEVICES=1
    build.env-append                COPY_FILE_RANGE_VERBOSE=1 RENAME_VERBOSE=1 RENAME_ACROSS_DEVICES=1
}

if {[variant_isset cputuned] || [variant_isset cpucompat]} {
    configure.cflags-append         {*}${LTO.cpuflags}
    configure.cxxflags-append       {*}${LTO.cpuflags}
    if {${os.platform} eq "darwin"} {
        configure.ldflags-append    {*}${LTO.cpuflags}
    }
}

if {[tbool configure.ccache] && [file exists ${prefix}/bin/sccache]} {
    # Enable sccache for rust caching
    set ::env(RUSTC_WRAPPER) ${prefix}/bin/sccache
    set ::env(SCCACHE_CACHE_SIZE) 2G
    set ::env(SCCACHE_DIR) [string map {".ccache" ".sccache"} ${ccache_dir}]
    set ::env(SCCACHE_STARTUP_NOTIFY) /tmp/mp-sccache-socket
}

if {![rustup::use_rustup]} {
    set cflags                      ${configure.cflags}
    set cxxflags                    ${configure.cxxflags}
    set ldflags                     ${configure.ldflags}
    ### include upstream rust PG
    PortGroup rust 1.0
    ###
    # deviate a bit from default behaviour: restore the compiler
    # and linker flags that were reset by the rust PG; idem
    # for compwrap.ccache_supported_compilers (requires custom
    # compiler_wrapper PG)
    # NB: I swear this was necessary at some point.. and then
    # the reset stopped happening?!
    if {${configure.cflags} eq {}} {
        configure.cflags            {*}${cflags}
    }
    if {${configure.cxxflags} eq {}} {
        configure.cxxflags          {*}${cxxflags}
    }
    # configure.ldflags can have rust-specific things set
    # so we use a different approach to prevent redundancy:
    configure.ldflags-delete        {*}${ldflags}
    configure.ldflags-append        {*}${ldflags}
    if {[info exists compwrap.stored_ccache_supported_compilers]} {
        default compwrap.ccache_supported_compilers ${compwrap.stored_ccache_supported_compilers}
    }
    unset cflags cxxflags ldflags
} else {
    # too tricky to remove the port:rust and port:cargo deps
   # that are added by the rust PG so we don't include it...
    PortGroup compiler_wrapper 1.0

    PortGroup muniversal 1.1

    if {${subport} ne "rustup"} {
        # we're not building port:rustup itself so we can depend on it
        # and use the openssl PG
        PortGroup openssl 1.0
        depends_build-append        port:rustup
    }
    if {${os.platform} eq "darwin"} {
        # make certain we use triplets that don't include ${os.major}
        triplet.os                  ${os.platform}
        if {${subport} eq "rustup"} {
            # for gmktemp:
            depends_build-append    port:coreutils
        }
        depends_build-append        port:cctools \
                                    port:curl
    }
    # configure.ld checking was done here.
    set env(RUSTUP_HOME)            ${rustup::home}
    set env(CARGO_HOME)             ${rustup::home}/Cargo
    set env(RUST_BACKTRACE)         "full"
#     set env(CARGO_PROFILE_RELEASE_BUILD_OVERRIDE_DEBUG) "true"
    # Rust does not easily pass external flags to compilers, so add them to compiler wrappers
    default compwrap.compilers_to_wrap \
                                    {cc cxx ld}
# why would we disable ccache'ing since this will happen in compiler wrappers?!
# don't change compwrap.ccache_supported_compilers!
    universal_variant no
}

# prepend our bin directory; this is safe even if we don't create it
# and this saves us from including conditional logic about adding it.
set env(PATH)                       ${rustup::home}/Cargo/bin:$env(PATH)

# adapted from or overriding the rust & cargo PGs:
options                             cargo.bin \
                                    cargo.offline_cmd \
                                    cargo.home \
                                    cargo.update
default cargo.offline_cmd           {--frozen}
default cargo.update                {no}
if {[rustup::use_rustup]} {
    default cargo.home              {$env(CARGO_HOME)}
#         default cargo.home          {${workpath}/.home/.cargo}
    default cargo.bin               {${rustup::home}/Cargo/bin/cargo}
} else {
    default cargo.bin               {${prefix}/bin/cargo}
}

if {![tbool rustup.disable_cargo]} {
    default build.cmd               {${cargo.bin} build}
    default build.target            {}
}
if {![tbool rustup.disable_cargo]} {
    if {[rustup::use_rustup]} {
        default configure.cmd       {${cargo.bin} update}
        default configure.pre_args  {}
        pre-configure {
            # by default we'll use the configure phase to show what packages/crates
            # could be updated. This is useful for e.g. openssl-sys in port:sccache;
            # the 0.9.60 version referenced by the source fails to build against
            # port:openssl3 (at least on Linux).
            # If `cargo update` allows the updating of specific crates only we
            # could consider providing an option var to select those, but for
            # now letting the port handle this through configure.args seems enough.
            if {![option cargo.update]} {
                default configure.pre_args \
                                    {--dry-run}
            } else {
                ui_msg "--->    Updating Cargo.lock"
            }
        }
        default build.pre_args      {--release -vv -j${build.jobs}}

        proc cargo.rust_platform {{arch ""}} {
            if {${arch} eq ""} {
                set arch [option muniversal.build_arch]
                # muniversal.build_arch is empty if we are not doing a universal build
                if {${arch} eq ""} {
                    set arch [option configure.build_arch]
                    if {${arch} eq ""} {
                        error "No build arch configured"
                    }
                }
            }
            return [option triplet.${arch}]
        }
    } else {
        default configure.cmd       {${cargo.bin} config}
        default configure.pre_args  {-Z unstable-options get}
        default build.pre_args      {--release ${cargo.offline_cmd} -vv -j${build.jobs}}
    }
    default build.args              {}
}

# it would be nice to generate a lean config.toml in rustup mode because
#     # normally we have only 1 toolchain installed
#     set cargos [glob -nocomplain ${rustup::home}/toolchains/stable-*/bin/cargo]
#     if {${cargos} ne {}} {
#         # rewrite the triplet.$arch options set by the muniversal PG to reflect
#         # what we actually have installed:
#         foreach arch {arm64 x86_64 i386 ppc ppc64} {
#             triplet.${arch}         "none"
#         }
#         foreach c ${cargos} {
#             set toolchain [split [file tail [file dirname [file dirname ${c}]]] '-']
#             set t3 [join [lrange ${toolchain} 1 3] -]
#             triplet.[lindex ${toolchain} 1] ${t3}
#         }
#         unset t3
#         unset toolchain
#         unset cargos
#     }
#     foreach arch {arm64 x86_64 i386 ppc ppc64} {
#         ui_debug "triplet.${arch}=[option triplet.${arch}]"
#     }

platform darwin {
    foreach stage {configure build destroot} {
        foreach arch [option muniversal.architectures] {
            if {[option triplet.${arch}] ne "none"} {
                ${stage}.env.${arch}-append "CARGO_BUILD_TARGET=[option triplet.${arch}]"
                ui_debug "${stage}.env.${arch}-append \"CARGO_BUILD_TARGET=[option triplet.${arch}]\""
            }
        }
    }
}

if {![tbool rustup.disable_cargo]} {
    destroot {
        ui_error "No destroot phase in the Portfile!"
        ui_msg "Here is an example destroot phase:"
        ui_msg
        ui_msg "destroot {"
        ui_msg {    xinstall -m 0755 ${worksrcpath}/target/[option triplet.${muniversal.build_arch}]/release/${name} ${destroot}${prefix}/bin/}
        ui_msg {    xinstall -m 0444 ${worksrcpath}/doc/${name}.1 ${destroot}${prefix}/share/man/man1/}
        ui_msg "}"
        ui_msg
        ui_msg "Please check if there are additional files (configuration, documentation, etc.) that need to be installed."
        error "destroot phase not implemented"
    }
}

namespace eval rustup {
    set includecounter [expr ${includecounter} + 1]
}
