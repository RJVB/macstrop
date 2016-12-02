# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
# kate: backspace-indents true; indent-pasted-text true; indent-width 4; keep-extra-spaces true; remove-trailing-spaces modified; replace-tabs true; replace-tabs-save true; syntax Tcl/Tk; tab-indents true; tab-width 4;
# $Id: qt5-1.0.tcl 113952 2015-06-11 16:30:53Z gmail.com:rjvbertin $
# $Id: qt5-1.0.tcl 113952 2013-11-26 18:01:53Z michaelld@macports.org $

# Copyright (c) 2014 The MacPorts Project
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
# PortGroup     qt5 1.0

if { ![exists universal_variant] || [option universal_variant] } {
    PortGroup muniversal 1.0
    #universal_archs_supported i386 x86_64
}

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

set qt_apps_dir             ${applications_dir}/Qt5
set qt_examples_dir         ${qt_apps_dir}/examples
set qt_demos_dir            ${qt_apps_dir}/demos

global qt_qmake_spec
global qt_qmake_spec_32
global qt_qmake_spec_64

PortGroup                   compiler_blacklist_versions 1.0
compiler.whitelist          clang macports-clang-3.5 macports-clang-3.4
compiler.blacklist-append   macports-llvm-gcc-4.2 llvm-gcc-4.2
compiler.blacklist-append   gcc-4.2 apple-gcc-4.2 gcc-4.0
compiler.blacklist-append   macports-clang-3.1 macports-clang-3.0 macports-clang-3.2 macports-clang-3.3
compiler.blacklist-append   {clang < 500}


# set Qt understood arch types, based on user preference
options qt_arch_types
default qt_arch_types       {[string map {i386 x86} [get_canonical_archs]]}

set qt_qmake_spec_32        macx-clang-32
set qt_qmake_spec_64        macx-clang

if { ![option universal_variant] || ![variant_isset universal] } {
    if { ${build_arch} eq "i386" } {
        set qt_qmake_spec   ${qt_qmake_spec_32}
    } else {
        set qt_qmake_spec   ${qt_qmake_spec_64}
    }
} else {
    set qt_qmake_spec ""
}

# standard PKGCONFIG path
global qt_pkg_config_dir
set qt_pkg_config_dir       ${prefix}/lib/pkgconfig

# data used by qmake
global qt_host_data_dir
set qt_host_data_dir        ${prefix}/share/${qt_name}

# standard cmake info for Qt5
global qt_cmake_defines
set qt_cmake_defines    \
    "-DQT_QT_INCLUDE_DIR=${qt_includes_dir} \
     -DQT_QMAKESPEC=${qt_qmake_spec} \
     -DQT_ZLIB_LIBRARY=${prefix}/lib/libz.dylib \
     -DQT_PNG_LIBRARY=${prefix}/lib/libpng.dylib"

# allow for depending on either qt5[-mac] or qt5[-mac]-devel or qt5[-mac]*-kde, simultaneously

if {![info exists building_qt5]} {
    if {${os.platform} eq "darwin"} {

        # see if the framework install exists, and if so depend on it;
        # if not, depend on the library version

        if {[file exists ${qt_frameworks_dir}/QtCore.framework/QtCore]} {
            depends_lib-append path:libexec/${qt_name}/Library/Frameworks/QtCore.framework/QtCore:qt5-mac
        } else {
            depends_lib-append path:libexec/${qt_name}/lib/libQtCore.5.dylib:qt5-mac
        }
    }
}

# standard configure environment, when not building qt5

if {![info exists building_qt5]} {
    configure.env-append \
        QTDIR=${qt_dir} \
        QMAKE=${qt_qmake_cmd} \
        MOC=${qt_moc_cmd}

    if { ![option universal_variant] || ![variant_isset universal] } {
        configure.env-append QMAKESPEC=${qt_qmake_spec}
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
        build.env-append QMAKESPEC=${qt_qmake_spec}
    } else {
        set merger_build_env(i386)      "QMAKESPEC=${qt_qmake_spec_32}"
        set merger_build_env(x86_64)    "QMAKESPEC=${qt_qmake_spec_64}"
        set merger_arch_flag            yes
        set merger_arch_compiler        yes
    }

    # make sure the Qt binaries' directory is in the path, if it is
    # not the current prefix

    if {${qt_dir} ne ${prefix}} {
        build.env-append                PATH=${qt_dir}/bin:$env(PATH)
    }
}

# use PKGCONFIG for Qt discovery in configure scripts
depends_build-append                    port:pkgconfig

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
        build.env-append QMAKESPEC=${qt_qmake_spec}
    } else {
        set destroot_build_env(i386)    "QMAKESPEC=${qt_qmake_spec_32}"
        set destroot_build_env(x86_64)  "QMAKESPEC=${qt_qmake_spec_64}"
    }

    # make sure the Qt binaries' directory is in the path, if it is
    # not the current prefix

    if {${qt_dir} ne ${prefix}} {
        destroot.env-append PATH=${qt_dir}/bin:$env(PATH)
    }
}

proc qt_branch {} {
    global version
    return [join [lrange [split ${version} .] 0 1] .]
}
