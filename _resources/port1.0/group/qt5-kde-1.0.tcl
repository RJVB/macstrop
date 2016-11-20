# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
# kate: backspace-indents true; indent-pasted-text true; indent-width 4; keep-extra-spaces true; remove-trailing-spaces modified; replace-tabs true; replace-tabs-save true; syntax Tcl/Tk; tab-indents true; tab-width 4;
# $Id: qt5-1.0.tcl 113952 2015-06-11 16:30:53Z gmail.com:rjvbertin $
# $Id: qt5-1.0.tcl 113952 2013-11-26 18:01:53Z michaelld@macports.org $

# Copyright (c) 2014 The MacPorts Project
# Copyright (c) 2015, 2016 R.J.V. Bertin
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
# This portgroup defines standard settings when using Qt5.
#
# Usage:
# set qt5.prefer_kde 1
# PortGroup     qt5 1.0
# or
# PortGroup     qt5-kde 1.0
#
# Define qt5.depends_qtwebengine before including the portgroup to add
# a dependency on qt5-kde-qtwebengine .

# shameless copy from the qt5-mac 1.0 PortGroup
# Qt has what is calls reference configurations, which are said to be thoroughly tested
# Qt also has configurations which are occasionally tested
# see http://doc.qt.io/qt-5/supported-platforms.html#reference-configurations
global qt5_min_tested_version
global qt5_max_tested_version
global qt5_min_reference_version
global qt5_max_reference_version
set qt5_min_tested_version     12
set qt5_max_tested_version     15
set qt5_min_reference_version  12
set qt5_max_reference_version  15

if {[tbool just_want_qt5_version_info]} {
    return
}

if {[file exists ${prefix}/libexec/qt5/plugins]
        && [file type ${prefix}/libexec/qt5/plugins] eq "directory"} {
    # Qt5 has been installed through port:qt5, which leads to certain incompatibilities
    # which do not need to be declared otherwise. The header Qt5 PortGroup has similar
    # checks and provisions, but since ports can also include us directly we have to
    # repeat them here.
    conflicts-append qt5-qtbase
    if {[info exists building_qt5]} {
        PortGroup conflicts_build 1.0
        conflicts_build-append qt5-qtbase
        ui_info "Qt5 has been installed through port:qt5 or its subports; you cannot build ${subport}"
        pre-fetch {
            return -code error "Deactivate the conflicting port:qt5 (subports) first!"
        }
        pre-configure {
            return -code error "Deactivate the conflicting port:qt5 (subports) first!"
        }
    } else {
        ui_info "Qt5 has been installed through port:qt5 or its subports; you can build but not install ${subport}"
    }
}
if {[info exists qt5.using_kde] && !${qt5.using_kde}} {
    # checks if the other Qt5 PortGroup has already been included.
    # NB: this works only when that happened through the qt5-1.0.tcl!
    ui_error "qt5-kde-1.0.tcl is being imported after qt5-mac-1.0.tcl"
    return -code error "importing 2 incompatible Qt5 PortGroups"
}

namespace eval qt5 {
    # our directory:
    variable currentportgroupdir [file dirname [dict get [info frame 0] file]]
}

# Ports that want to provide a universal variant need to use the muniversal PortGroup explicitly.
universal_variant no

# check for +debug variant of this port, and make sure Qt was
# installed with +debug as well; if not, error out.
platform darwin {
    pre-extract {
        if {[variant_exists debug] && \
            [variant_isset debug] && \
           ![info exists building_qt5]} {
            if {![file exists ${qt_frameworks_dir}/QtCore.framework/QtCore_debug]} {
                return -code error "\n\nERROR:\n\
In order to install this port as +debug,
Qt5 must also be installed with +debug.\n"
            }
        }
    }
}

if {![variant_exists qt5kde]} {
    # define a variant that will be set default when port:qt5-kde or port:qt5-kde-devel is
    # installed. This means that a user doing a new install (or upgrade) of a port depending
    # on Qt5 and with port:qt5-kde installed will request a variant the build bots should not
    # consider a default variant. This meant to protect against pulling in a binary build against
    # the wrong Qt5 port, which was relevant in the time of port:qt5-mac, and hopefully no
    # longer now that port:qt5 installs to the same place as we do (but as an all-inclusive prefix).
    variant qt5kde description {default variant set for port:qt5-kde* and ports that depend on them} {}
}
# it should no longer be necessary to set qt5kde but we will continue to do so for now.
default_variants        +qt5kde

# standard Qt5 name. This should be just "qt5" (or qt53 for instance when more
# specific version info must be included). There is nothing but a historical reason
# to call the Qt5 port itself qt5-mac, so that name should not appear on disk where
# files could be installed that would be the distant descendants of files from qt4-x11
global qt_name
set qt_name             qt5

# global definitions with explanation; set the actual values below for cleanness.
# standard install directory
    global qt_dir
# idem, relative to ${prefix}
    global qt_dir_rel
# archdata: equal to qt_dir
    global qt_archdata_dir
# standard Qt documents directory
    global qt_docs_dir
# standard Qt plugins directory
    global qt_plugins_dir
# standard Qt mkspecs directory
    global qt_mkspecs_dir
# standard Qt imports directory
    global qt_imports_dir
# standard Qt qml directory
    global qt_qml_dir
# standard Qt includes directory, under ${prefix}/includes where they would be expected
    global qt_includes_dir
# standard Qt libraries directory
    global qt_libs_dir
# standard Qt libraries directory: OS X frameworks
    global qt_frameworks_dir
# idem, relative to ${prefix}
    global qt_frameworks_dir_rel
# standard Qt non-.app executables directory
    global qt_bins_dir
# standard Qt data directory
    global qt_data_dir
# standard Qt translations directory
    global qt_translations_dir
# standard Qt sysconf directory
    global qt_sysconf_dir
# standard Qt .app executables directory, if created
    global qt_apps_dir
# standard Qt examples directory
    global qt_examples_dir
# standard Qt demos directory
    global qt_demos_dir
# standard Qt tests directory
    global qt_tests_dir
# standard CMake module directory for Qt-related files
    global qt_cmake_module_dir
# standard qmake command location
    global qt_qmake_cmd
# standard moc command location
    global qt_moc_cmd
# standard uic command location
    global qt_uic_cmd
# standard lrelease command location
    global qt_lrelease_cmd
    global qt_lupdate_cmd

global qt5_is_concurrent
# check if we're building qt5 itself. We're aiming to phase out exclusive installs, but we
# keep the this block for now that handles detection of the nature of the installed port.
# if {![info exists building_qt5] || ![info exists name] \
#     || (${name} ne "qt5-mac" && ${name} ne "qt5-mac-devel" && ${name} ne "qt5-kde" && ${name} ne "qt5-kde-devel")} {
#     # no, this must be a dependent port: check the qt5 install:
#     if {[file exists ${prefix}/libexec/${qt_name}/bin/qmake]} {
#         # we have a "concurrent" install, which means we must look for the various components
#         # in different locations (esp. qmake)
#         set qt5_is_concurrent   1
#     }
# } else {
#     # we're building qt5, qt5-mac or one of its subports/variants
#     # we're asking for the standard concurrent install. No need to guess anything, give the user what s/he wants
#     set qt5_is_concurrent   1
# }
set qt5_is_concurrent       1

set qt_dir                  ${prefix}/libexec/${qt_name}
set qt_dir_rel              libexec/${qt_name}
set qt_includes_dir         ${prefix}/include/${qt_name}
set qt_libs_dir             ${qt_dir}/lib
set qt_frameworks_dir       ${qt_dir}/Library/Frameworks
set qt_frameworks_dir_rel   ${qt_dir_rel}/Library/Frameworks
set qt_bins_dir             ${qt_dir}/bin
set qt_cmake_module_dir     ${prefix}/lib/cmake
set qt_archdata_dir         ${qt_dir}
set qt_sysconf_dir          ${prefix}/etc/${qt_name}
set qt_data_dir             ${prefix}/share/${qt_name}
set qt_plugins_dir          ${prefix}/share/${qt_name}/plugins
set qt_mkspecs_dir          ${prefix}/share/${qt_name}/mkspecs
set qt_imports_dir          ${prefix}/share/${qt_name}/imports
set qt_qml_dir              ${prefix}/share/${qt_name}/qml
set qt_translations_dir     ${prefix}/share/${qt_name}/translations
set qt_tests_dir            ${prefix}/share/${qt_name}/tests
set qt_docs_dir             ${prefix}/share/doc/${qt_name}

set qt_qmake_cmd            ${qt_dir}/bin/qmake
set qt_moc_cmd              ${qt_dir}/bin/moc
set qt_uic_cmd              ${qt_dir}/bin/uic
set qt_lrelease_cmd         ${qt_dir}/bin/lrelease
set qt_lupdate_cmd          ${qt_dir}/bin/lupdate

if {${os.platform} eq "darwin"} {
    set qt_apps_dir         ${applications_dir}/Qt5
} else {
    set qt_apps_dir         ${qt_bins_dir}
}
set qt_examples_dir         ${qt_apps_dir}/examples
set qt_demos_dir            ${qt_apps_dir}/demos

global qt_qmake_spec
global qt_qmake_spec_32
global qt_qmake_spec_64

PortGroup                   compiler_blacklist_versions 1.0
if {${os.platform} eq "darwin"} {
    compiler.whitelist      clang
#     compiler.whitelist      clang macports-clang-3.7 macports-clang-3.6 macports-clang-3.5 macports-clang-3.4
}
compiler.blacklist-append   macports-llvm-gcc-4.2 llvm-gcc-4.2
compiler.blacklist-append   gcc-4.2 apple-gcc-4.2 gcc-4.0
compiler.blacklist-append   {clang < 500}
# # starting with the one-but-newest macports-clang in the whitelist, check it it is
# # installed and blacklist the other values so that the automatic selection mechanism
# # will select the installed whitelisted version.
# foreach v {3.6 3.5 3.4} {
#     if {[file exists ${prefix}/libexec/llvm-${v}/bin/clang]} {
#         foreach o {3.7 3.6 3.5 3.4} {
#             if {${o} ne ${v}} {
#                 compiler.blacklist-append   macports-clang-${o}
#             }
#         }
#     }
# }

if {[file exists ${qt5::currentportgroupdir}/macports_clang_selection-1.0.tcl]} {
    PortGroup               macports_clang_selection 1.0
    if {${os.platform} eq "darwin"} {
        if {${os.platform} > 10} {
            whitelist_macports_clang_versions   {3.7 3.6 3.5 3.4}
        } else {
            whitelist_macports_clang_versions   {3.5 3.4}
        }
        blacklist_macports_clang_versions       {< 3.4}
    }
}

# set Qt understood arch types, based on user preference
options qt_arch_types
default qt_arch_types {[string map {i386 x86} [get_canonical_archs]]}

if {${os.platform} eq "darwin"} {
    set qt_qmake_spec_32 macx-clang-32
    set qt_qmake_spec_64 macx-clang
} elseif {${os.platform} eq "linux"} {
    set qt_qmake_spec_32 linux-g++
    set qt_qmake_spec_64 linux-g++-64
    compiler.blacklist-append   clang
}

if { ![option universal_variant] || ![variant_isset universal] } {
    if { ${build_arch} eq "i386" } {
        set qt_qmake_spec ${qt_qmake_spec_32}
    } else {
        set qt_qmake_spec ${qt_qmake_spec_64}
    }
} else {
    set qt_qmake_spec ""
}

# standard PKGCONFIG path
global qt_pkg_config_dir
set qt_pkg_config_dir   ${prefix}/lib/pkgconfig

# data used by qmake
global qt_host_data_dir
set qt_host_data_dir   ${prefix}/share/${qt_name} 

# standard cmake info for Qt5
global qt_cmake_defines
set qt_cmake_defines    \
    "-DQT_QT_INCLUDE_DIR=${qt_includes_dir} \
     -DQT_ZLIB_LIBRARY=${prefix}/lib/libz.dylib \
     -DQT_PNG_LIBRARY=${prefix}/lib/libpng.dylib"
if {${qt_qmake_spec} ne ""} {
    set qt_cmake_defines \
        "${qt_cmake_defines} -DQT_QMAKESPEC=${qt_qmake_spec}"
}

if {${os.platform} eq "darwin"} {
    # extensions on shared libraries
    set qt_libs_ext     dylib
    # extensions on plugins created by Qt's build system
    set qt_plugins_ext  dylib
} else {
    set qt_libs_ext     so
    set qt_plugins_ext  so
}

# allow for depending on either qt5[-mac] or qt5[-mac]-devel or qt5[-mac]*-kde, simultaneously

set qt5_stubports   {qtbase qtdeclarative qtserialbus qtserialport qtsensors \
                qtquick1 qtwebchannel qtimageformats qtsvg qtmacextras \
                qtlocation qtxmlpatterns qtcanvas3d qtgraphicaleffects qtmultimedia \
                qtscript qt3d qtconnectivity qttools qtquickcontrols qtenginio \
                qtwebkit-examples qtwebsockets qttranslations docs mysql-plugin \
                sqlite-plugin}

global qt5_dependency
global qt5webkit_dependency
if {${os.platform} eq "darwin"} {
    # see if the framework install exists, and if so depend on it;
    # if not, depend on the library version
    if {[file exists ${qt_frameworks_dir}/QtCore.framework/QtCore]} {
        set qt5_pathlibspec path:libexec/${qt_name}/Library/Frameworks/QtCore.framework/QtCore
    } else {
        set qt5_pathlibspec path:libexec/${qt_name}/lib/libQtCore.${qt_libs_ext}
    }
    set qt5_dependency ${qt5_pathlibspec}:qt5-kde
    if {[file exists ${qt_frameworks_dir}/QtWebKit.framework/QtWebKit]} {
        set qt5_pathlibspec path:libexec/${qt_name}/Library/Frameworks/QtWebKit.framework/QtWebKit
    } else {
        set qt5_pathlibspec path:libexec/${qt_name}/lib/libQtWebKit.${qt_libs_ext}
    }
    set qt5webkit_dependency ${qt5_pathlibspec}:qt5-kde-qtwebkit
    set qt5webengine_dependency \
                        path:libexec/${qt_name}/Library/Frameworks/QtWebEngineCore.framework/QtWebEngineCore:qt5-kde-qtwebengine
} elseif {${os.platform} eq "linux"} {
    set qt5_pathlibspec path:libexec/${qt_name}/lib/libQt5Core.${qt_libs_ext}
    set qt5_dependency ${qt5_pathlibspec}:qt5-kde
    set qt5webkit_dependency path:libexec/${qt_name}/lib/libQt5WebKit.${qt_libs_ext}:qt5-kde-qtwebkit
    set qt5webengine_dependency \
                        path:libexec/${qt_name}/lib/libQt5WebEngineCore.${qt_libs_ext}:qt5-kde-qtwebengine
}
if {![info exists building_qt5]} {
    depends_lib-append ${qt5_dependency}
    if {[info exists qt5.depends_qtwebengine] && ${qt5.depends_qtwebengine}} {
        depends_lib-append \
                        ${qt5webengine_dependency}
    }
}

variant LTO description {Build with Link-Time Optimisation (LTO) (experimental)} {}

if {![info exists building_qt5] && [variant_exists LTO] && [variant_isset LTO]} {
    configure.cflags-append     -flto
    configure.cxxflags-append   -flto
    configure.objcflags-append  -flto
    configure.objcxxflags-append  -flto
    # ${configure.optflags} is a list, and that can lead to strange effects
    # in certain situations if we don't treat it as such here.
    foreach opt ${configure.optflags} {
        configure.ldflags-append ${opt}
    }
    configure.ldflags-append    -flto
    # assume any compiler not clang will be gcc
    if {![string match "*clang*" ${configure.compiler}]} {
        configure.cflags-append         -fuse-linker-plugin -ffat-lto-objects
        configure.cxxflags-append       -fuse-linker-plugin -ffat-lto-objects
        configure.objcflags-append      -fuse-linker-plugin -ffat-lto-objects
        configure.objcxxflags-append    -fuse-linker-plugin -ffat-lto-objects
        configure.ldflags-append        -fuse-linker-plugin
    }
}

# standard configure environment, when not building qt5

if {![info exists building_qt5]} {
    configure.env-append \
        QTDIR=${qt_dir} \
        QMAKE=${qt_qmake_cmd} \
        MOC=${qt_moc_cmd}

    if { ![option universal_variant] || ![variant_isset universal] } {
        if {${qt_qmake_spec} ne ""} {
            configure.env-append QMAKESPEC=${qt_qmake_spec}
        }
    } else {
        set merger_configure_env(i386)   "QMAKESPEC=${qt_qmake_spec_32}"
        set merger_configure_env(x86_64) "QMAKESPEC=${qt_qmake_spec_64}"
        set merger_arch_flag             yes
        set merger_arch_compiler         yes
    }

    # make sure the Qt binaries' directory is in the path, if it is
    # not the current prefix

    if {${qt_dir} ne ${prefix}} {
        configure.env-append PATH=${qt_dir}/bin:$env(PATH)
    }
} else {
    configure.env-append QMAKE_NO_DEFAULTS=""
}

# standard build environment, when not building qt5

if {![info exists building_qt5]} {
    build.env-append \
        QTDIR=${qt_dir} \
        QMAKE=${qt_qmake_cmd} \
        MOC=${qt_moc_cmd}

    if { ![option universal_variant] || ![variant_isset universal] } {
        if {${qt_qmake_spec} ne ""} {
            build.env-append QMAKESPEC=${qt_qmake_spec}
        }
    } else {
        set merger_build_env(i386)   "QMAKESPEC=${qt_qmake_spec_32}"
        set merger_build_env(x86_64) "QMAKESPEC=${qt_qmake_spec_64}"
        set merger_arch_flag             yes
        set merger_arch_compiler         yes
    }

    # make sure the Qt binaries' directory is in the path, if it is
    # not the current prefix

    if {${qt_dir} ne ${prefix}} {
        build.env-append    PATH=${qt_dir}/bin:$env(PATH)
    }
}

# use PKGCONFIG for Qt discovery in configure scripts
depends_build-append    port:pkgconfig

# standard destroot environment
if { ![option universal_variant] || ![variant_isset universal] } {
    destroot.env-append \
        INSTALL_ROOT=${destroot}
} else {
    foreach arch ${configure.universal_archs} {
        lappend merger_destroot_env($arch) INSTALL_ROOT=${workpath}/destroot-${arch}
    }
}

# standard destroot environment, when not building qt5

if {![info exists building_qt5]} {
    destroot.env-append \
        QTDIR=${qt_dir} \
        QMAKE=${qt_qmake_cmd} \
        MOC=${qt_moc_cmd}

    if { ![option universal_variant] || ![variant_isset universal] } {
        if {${qt_qmake_spec} ne ""} {
            build.env-append QMAKESPEC=${qt_qmake_spec}
        }
    } else {
        set destroot_build_env(i386)   "QMAKESPEC=${qt_qmake_spec_32}"
        set destroot_build_env(x86_64) "QMAKESPEC=${qt_qmake_spec_64}"
    }

    # make sure the Qt binaries' directory is in the path, if it is
    # not the current prefix

    if {${qt_dir} ne ${prefix}} {
        destroot.env-append PATH=${qt_dir}/bin:$env(PATH)
    }
}

# provide a variant to prune provided translations
# make this optional so the locale_select portgroup doesn't need to be made public/official
# the easy way to do that would be to catch the PortGroup statement
# but that will print warnings for everyone who doesn't have the
# the PortGroup installed. Other solution: check for
# [info exist ::env(MACPORTS_QT5KDE_LANGSELECT)] && $::env(MACPORTS_QT5KDE_LANGSELECT)
# Easy solution: check if the config file exists because without that the feature is disabled anyway.
if {[file exists ${prefix}/etc/macports/locales.tcl]} {
    PortGroup   locale_select 1.0
    # Qt translations don't go into ${prefix}/opt/local/share/locale:
    post-destroot {
        if {![info exists keep_languages]} {
            if {[file exists ${destroot}${qt_translations_dir}]} {
                if {[catch {source "${prefix}/etc/macports/locales.tcl"} err]} {
                    ui_error "Error reading ${prefix}/etc/macports/locales.tcl: $err"
                    return -code error "Error reading ${prefix}/etc/macports/locales.tcl"
                }
            }
        }
        if {[info exists keep_languages]} {
            foreach l [glob -nocomplain ${destroot}${qt_translations_dir}/*.qm] {
                set langcomps [split [file rootname [file tail ${l}]] _]
                set simplelang [lindex ${langcomps} end]
                set complang [join [lrange ${langcomps} end-1 end] _]
                if {[lsearch -exact ${keep_languages} ${simplelang}] ne "-1"} {
                    ui_debug "won't delete ${l} (${simplelang})"
                } elseif {[lsearch -exact ${keep_languages} ${complang}] ne "-1"} {
                    ui_debug "won't delete ${l} (${complang})"
                } else {
                    ui_debug "rm ${l}"
                    file delete -force ${l}
                }
            }
        }
    }
}

# convenience function for revision management
proc revbump_for_version {r v {p 0}} {
    global version revision subport os.platform
    if {${p} eq 0 || ${os.platform} eq ${p}} {
        if {[vercmp ${version} ${v}] > 0} {
            return -code error "remove revbump (revision ${r}) for ${subport}"
        }
        uplevel set revision ${r}
    }
}

# create a wrapper script in ${prefix}/bin for an application bundle in qt_apps_dir
options qt5.wrapper_env_additions
default qt5.wrapper_env_additions ""

proc qt5.add_app_wrapper {wrappername {bundlename ""} {bundleexec ""} {appdir ""}} {
    global qt_apps_dir destroot prefix os.platform qt5.wrapper_env_additions subport
    if {${appdir} eq ""} {
        set appdir ${qt_apps_dir}
    }
    xinstall -m 755 -d ${destroot}${prefix}/bin
    if {![catch {set fd [open "${destroot}${prefix}/bin/${wrappername}" "w"]} err]} {
        # this wrapper exists to a large extent to improve integration of "pure" qt5
        # apps with KF5 apps, in particular through the use of the KDE platform theme plugin
        # Hence the reference to KDE things in the preamble.
        puts ${fd} "#!/bin/sh\n\
            if \[ -r ~/.kf5.env \] ;then\n\
            \t. ~/.kf5.env\n\
            else\n\
            \texport KDE_SESSION_VERSION=5\n\
            fi"
        set wrapper_env_additions "[join ${qt5.wrapper_env_additions}]"
        if {${wrapper_env_additions} ne ""} {
            puts ${fd} "# Additional env. variables specified by port:${subport} :"
            puts ${fd} "export ${wrapper_env_additions}"
            puts ${fd} "#"
        }
        if {${os.platform} eq "darwin"} {
            if {${bundlename} eq ""} {
                set bundlename ${wrappername}
            }
            if {${bundleexec} eq ""} {
                set bundleexec ${bundlename}
            }
            puts ${fd} "exec \"${appdir}/${bundlename}.app/Contents/MacOS/${bundleexec}\" \"\$\@\""
        } else {
            global qt_libs_dir
            # no app bundles on this platform, but provide the same API by pretending there are.
            # If unset, use ${subport} to guess the exec. name because evidently we cannot
            # symlink ${wrappername} onto itself.
            if {${bundlename} eq ""} {
                set bundlename ${subport}
            }
            if {${bundleexec} eq ""} {
                set bundleexec ${bundlename}
            }
            puts ${fd} "export LD_LIBRARY_PATH=\$\{LD_LIBRARY_PATH\}:${prefix}/lib:${qt_libs_dir}"
            puts ${fd} "exec \"${appdir}/${bundleexec}\" \"\$\@\""
            close ${fd}
        }
        system "chmod 755 ${destroot}${prefix}/bin/${wrappername}"
    } else {
        ui_error "Failed to (re)create \"${destroot}${prefix}/bin/${wrappername}\" : ${err}"
        return -code error ${err}
    }
}

###############################################################################
# define the qt5_component_lib array element-by-element instead of in a table;
# using a table wouldn't allow the use of variables (they wouldn't be expanded)
platform darwin {
    set qt5_component_lib(qtwebkit)     path:libexec/${qt_name}/Library/Frameworks/QtWebKit.framework/QtWebKit
        set qt5_component_lib(qtwebengine)  path:libexec/${qt_name}/Library/Frameworks/QtWebEngine.framework/QtWebEngine
}
platform linux {
    set qt5_component_lib(qtwebkit)     path:libexec/${qt_name}/lib/libQt5WebKit.${qt_libs_ext}
        set qt5_component_lib(qtwebengine)  path:libexec/${qt_name}/lib/libQt5WebEngineCore.${qt_libs_ext}
}

