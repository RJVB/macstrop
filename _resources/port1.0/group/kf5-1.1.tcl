# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4
# $Id: kf5-1.0.tcl 134210 2015-03-20 06:40:18Z mk@macports.org $

# Copyright (c) 2015 The MacPorts Project
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
# PortGroup     kf5 1.0

PortGroup               cmake 1.0
# set qt5.prefer_kde      1
PortGroup               qt5-kde 1.0

########################################################################
# Projects including the 'kf5' port group can optionally set
#
#  - their project name as 'kf5.project'
#
# in that case, they should specify whether they are
#
#  - a framework by defining 'kf5.framework'
#
#  - a porting aid by defining 'kf5.portingAid'
#
#  - or a regular KF5 project which requires setting
#    + a virtual path in 'kf5.virtualPath' (e.g. "applications")
#    + as well as (optionally) a release in 'kf5.release' (e.g. "15.04.2")
#    + or (optionally) a plasma version in 'kf5.plasma' (e.g. 5.4.3)
#
# otherwise the port will fail to build.
########################################################################

if { ![ info exists kf5.project ] } {
    ui_debug "kf5.project is not defined; falling back to \"manual\" configuration"
} else {
    name                kf5-${kf5.project}
}

# KF5 frameworks current version, which is the same for all frameworks
if {![info exists kf5.version]} {
    set kf5.version     5.16.0
}

# KF5 Applications version
if {![ info exists kf5.release ]} {
    set kf5.release     15.08.3
}

# KF5 Plasma version
if {![ info exists kf5.plasma ]} {
    set kf5.plasma      5.4.3
}

platforms               darwin linux
categories              kde kf5 devel
license                 GPL-2+

set kf5.branch           [join [lrange [split ${kf5.version} .] 0 1] .]

# Make sure to not use any already installed headers and libraries;
# these are set in CPATH and LIBRARY_PATH anyway.
configure.ldflags-delete  -L${prefix}/lib
configure.cppflags-delete -I${prefix}/include

# setup all KF5 ports to build in a separate directory from the source:
cmake.out_of_source     yes

# NOTE: Many kf5 ports violate MacPorts' ports file systems,
#       but it is a must due to Qt5's QStandardPaths logic,
#       so we'll quieten the warning.
# destroot.violate_mtree  yes

# TODO:
#
# Phonon added as library dependency here as most, if not all KDE
# programs current need it.  The phonon port, which includes this
# PortGroup overrides depends_lib, removing "port:phonon" to prevent a
# cyclic dependency
#depends_lib-append      port:phonon

# This is used by all KF5 frameworks
depends_lib-append      path:share/ECM/cmake/ECMConfig.cmake:kde-extra-cmake-modules

# Use directory set by qt5-kde or qt5-mac
configure.args-append   -DECM_MKSPECS_INSTALL_DIR=${qt_mkspecs_dir}

# set a best-compromise plugin destination directory, the one from Qt5.
# this is also what Kubuntu does, and possibly the only way to ensure that Qt5
# and KF5 find each other's (and their own...) plugins.
configure.args-append   -DPLUGIN_INSTALL_DIR=${qt_plugins_dir} \
                        -DKDE_INSTALL_QTPLUGINDIR=${qt_plugins_dir}

# # This is why we need destroo.violate_mtree set to "yes"
# configure.args-append   -DCONFIG_INSTALL_DIR="/Library/Preferences" \
#                         -DDATA_INSTALL_DIR="/Library/Application Support"
#
# Actually this should be used instead of DATA_INSTALL_DIR, but it doesn't work:
#                       -DKDE_INSTALL_DATADIR_KF5="/Library/Application Support"

# Q: What about the often used XDG dir?
#    (Currently it gets installed into /etc/xdg just like on Linux.)

# standard configure args
configure.args-append   -DBUILD_doc=OFF \
                        -DBUILD_docs=OFF \
                        -DBUILD_SHARED_LIBS=ON
if {${os.platform} eq "darwin"} {
    set kf5.applications_dir \
                        ${applications_dir}/KF5
    configure.args-append \
                        -DBUNDLE_INSTALL_DIR=${kf5.applications_dir} \
                        -DCMAKE_DISABLE_FIND_PACKAGE_X11=ON \
                        -DAPPLE_SUPPRESS_X11_WARNING=ON \
                        -DCMAKE_INSTALL_LIBEXECDIR=${prefix}/libexec \
                        -DKDE_INSTALL_LIBEXECDIR=${prefix}/libexec/kde5
} elseif {${os.platform} eq "linux"} {
    set kf5.applications_dir \
                        ${prefix}/bin
    configure.args-delete \
                        -DCMAKE_INSTALL_RPATH=${prefix}/lib
    configure.args-append \
                        -DCMAKE_PREFIX_PATH=${prefix} \
                        -DCMAKE_INSTALL_RPATH="${prefix}/lib/${os.arch}-linux-gnu\;${prefix}/lib"
}
set kf5.docs_dir        ${prefix}/share/doc/kf5

set kf5.allow_docs_generation \
                        yes
variant docs description {build and install the documentation, for use with Qt's Assistant and KDevelop} {
    configure.args-delete \
                        -DBUILD_doc=OFF \
                        -DBUILD_docs=OFF
    if {${subport} ne "kf5-kapidox"} {
        if {[info exists kf5.allow_docs_generation]} {
            kf5.depends_build_frameworks \
                        kapidox
            post-destroot {
                # generate the documentation, working from ${build.dir}
                system -W ${build.dir} "kgenapidox --qhp --searchengine --api-searchbox \
                    --qtdoc-dir ${qt_docs_dir} --kdedoc-dir ${kf5.docs_dir} \
                    --qhelpgenerator ${qt_bins_dir}/qhelpgenerator ${worksrcpath}"
                xinstall -m 755 -d ${destroot}${kf5.docs_dir}
                # after creating the destination, copy all generated qch documentation to it
                foreach doc [glob -nocomplain ${build.dir}/apidocs/qch/*.qch] {
                    if {${doc} ne "${build.dir}/apidocs/qch/None.qch"} {
                        xinstall -m 644 ${doc} ${destroot}${kf5.docs_dir}
                    }
                }
                # cleanup
                file delete -force ${build.dir}/apidocs
            }
        }
    }
}

if {${os.platform} eq "darwin"} {
   set kf5.libs_dir    ${prefix}/lib
   set kf5.libs_ext    dylib
} elseif {${os.platform} eq "linux"} {
   set kf5.libs_dir    ${prefix}/lib/${os.arch}-linux-gnu
   set kf5.libs_ext    so
}

if {![info exists kf5.framework]} {
    # explicitly define certain headers and libraries, to avoid
    # conflicts with those installed into system paths by the user.
    configure.args-append \
                        -DDOCBOOKXSL_DIR=${prefix}/share/xsl/docbook-xsl \
                        -DGETTEXT_INCLUDE_DIR=${prefix}/include \
                        -DGETTEXT_LIBRARY=${prefix}/lib/libgettextlib.${kf5.libs_ext} \
                        -DGIF_INCLUDE_DIR=${prefix}/include \
                        -DGIF_LIBRARY=${prefix}/lib/libgif.${kf5.libs_ext} \
                        -DJASPER_INCLUDE_DIR=${prefix}/include \
                        -DJASPER_LIBRARY=${prefix}/lib/libjasper.${kf5.libs_ext} \
                        -DJPEG_INCLUDE_DIR=${prefix}/include \
                        -DJPEG_LIBRARY=${prefix}/lib/libjpeg.${kf5.libs_ext} \
                        -DLBER_LIBRARIES=${prefix}/lib/liblber.${kf5.libs_ext} \
                        -DLDAP_INCLUDE_DIR=${prefix}/include \
                        -DLDAP_LIBRARIES=${prefix}/lib/libldap.${kf5.libs_ext} \
                        -DLIBEXSLT_INCLUDE_DIR=${prefix}/include \
                        -DLIBEXSLT_LIBRARIES=${prefix}/lib/libexslt.${kf5.libs_ext} \
                        -DLIBICALSS_LIBRARY=${prefix}/lib/libicalss.${kf5.libs_ext} \
                        -DLIBICAL_INCLUDE_DIRS=${prefix}/include \
                        -DLIBICAL_LIBRARY=${prefix}/lib/libical.${kf5.libs_ext} \
                        -DLIBINTL_INCLUDE_DIR=${prefix}/include \
                        -DLIBINTL_LIBRARY=${prefix}/lib/libintl.${kf5.libs_ext} \
                        -DLIBXML2_INCLUDE_DIR=${prefix}/include/libxml2 \
                        -DLIBXML2_LIBRARIES=${prefix}/lib/libxml2.${kf5.libs_ext} \
                        -DLIBXML2_XMLLINT_EXECUTABLE=${prefix}/bin/xmllint \
                        -DLIBXSLT_INCLUDE_DIR=${prefix}/include \
                        -DLIBXSLT_LIBRARIES=${prefix}/lib/libxslt.${kf5.libs_ext} \
                        -DOPENAL_INCLUDE_DIR=/System/Library/Frameworks/OpenAL.framework/Headers \
                        -DOPENAL_LIBRARY=/System/Library/Frameworks/OpenAL.framework \
                        -DPNG_INCLUDE_DIR=${prefix}/include \
                        -DPNG_PNG_INCLUDE_DIR=${prefix}/include \
                        -DPNG_LIBRARY=${prefix}/lib/libpng.${kf5.libs_ext} \
                        -DTIFF_INCLUDE_DIR=${prefix}/include \
                        -DTIFF_LIBRARY=${prefix}/lib/libtiff.${kf5.libs_ext}
}

if { [ info exists kf5.portingAid ] } {
    set kf5.virtualPath     "frameworks"
    set kf5.folder          "frameworks/${kf5.branch}/portingAids"
}

if { [ info exists kf5.framework ] } {
    set kf5.virtualPath     "frameworks"
    set kf5.folder          "frameworks/${kf5.branch}"
}

if {[info exists kf5.project]} {
    if { ![ info exists kf5.framework ] && ![ info exists kf5.portingAid ] } {
        if { ![ info exists kf5.virtualPath ] } {
            ui_error "You haven't defined kf5.virtualPath, which is mandatory for any KF5 port that uses kf5.project. \
            (Or is this project perhaps a framework or porting aid?)"
            return -code error "incomplete port definition"
        } else {
            if { ![info exists kf5.release] && ![info exists kf5.plasma]} {
                ui_error "You haven't defined kf5.release or kf5.plasma, which is mandatory for any KF5 port that uses kf5.project."
                return -code error "incomplete port definition"
            } else {
                if {${kf5.virtualPath} eq "plasma"} {
                    set kf5.folder \
                            "${kf5.virtualPath}/${kf5.plasma}"
                    distname \
                            ${kf5.project}-${kf5.plasma}
                    version \
                            ${kf5.plasma}
                } else {
                    set kf5.folder \
                            "${kf5.virtualPath}/${kf5.release}/src"
                    distname \
                            ${kf5.project}-${kf5.release}
                    version \
                            ${kf5.release}
                }
            }
        }
    } else {
        distname            ${kf5.project}-${kf5.version}
    }
    homepage                http://projects.kde.org/projects/${kf5.virtualPath}/${kf5.project}
    master_sites            http://download.kde.org/stable/${kf5.folder}
    use_xz                  yes
}

# maintainers             gmail.com:rjvbertin mk openmaintainer

post-fetch {
    if {[file exists ${worksrcpath}/examples] && [file isdirectory ${worksrcpath}/examples] && ![variant_exists examples]} {
        ui_msg "This port could provide a +examples variant"
    }
}

post-build {
    if {[file exists ${prefix}/bin/afsctool]} {
        ui_msg "--->  Compressing build directory ..."
        if {[catch {system "${prefix}/bin/afsctool -cfvv -8 -J${build.jobs} ${build.dir} 2>&1"} result context]} {
            ui_msg "Compression failed: ${result}, ${context}; port:afsctool is probably installed without support for parallel compression"
        } else {
            ui_debug "Compressing ${build.dir}: ${result}"
        }
    }
}

proc kf5.add_test_library_path {path} {
    global os.platform
    if {${os.platform} eq "darwin"} {
        test.env    DYLD_LIBRARY_PATH=${path}
    } else {
        test.env    LD_LIBRARY_PATH=${path}
    }
}

# variables to facilitate setting up dependencies to KF5 frameworks that may (or not)
# also exist as port:kf5-foo-devel .
proc kf5.framework_dependency {name {library 0}} {
    upvar #0 kf5.${name}_dep dep
    if {${library} ne 0} {
        global os.platform os.arch
        if {${os.platform} eq "darwin"} {
            set kf5.lib_path    lib
            set kf5.lib_ext     5.dylib
        } elseif {${os.platform} eq "linux"} {
            set kf5.lib_path    lib/${os.arch}-linux-gnu
            set kf5.lib_ext     so.5
        }
        set dep                 path:${kf5.lib_path}/${library}.${kf5.lib_ext}:kf5-${name}
        ui_debug "Dependency expression for KF5ramework ${name}: ${dep}"
    } else {
        if {[info exists dep]} {
            return ${dep}
        } else {
            set allknown [info global "kf5.*_dep"]
            ui_error "No KF5 framework is known corresponding to \"${name}\""
            ui_msg "Known framework ports: ${allknown}"
            return -code error "Unknown KF5 framework ${name}"
        }
    }
}

# kf5.depends_frameworks appends the ports corresponding to the KF5 Frameworks
# short names to depends_lib
proc kf5.depends_frameworks {first args} {
    depends_lib-append  [kf5.framework_dependency ${first}]
    foreach f ${args} {
        depends_lib-append \
                        [kf5.framework_dependency ${f}]
    }
}
proc kf5.depends_build_frameworks {first args} {
    depends_build-append \
                        [kf5.framework_dependency ${first}]
    foreach f ${args} {
        depends_build-append \
                        [kf5.framework_dependency ${f}]
    }
}

kf5.framework_dependency    attica libKF5Attica
kf5.framework_dependency    karchive libKF5Archive
kf5.framework_dependency    kcoreaddons libKF5CoreAddons
kf5.framework_dependency    kauth libKF5Auth
kf5.framework_dependency    kconfig libKF5ConfigCore
kf5.framework_dependency    kcodecs libKF5Codecs
kf5.framework_dependency    ki18n libKF5I18n
# kf5-kdoctools does install a static library but I don't know if it has dependents
set kf5.kdoctools_dep       path:bin/meinproc5:kf5-kdoctools
kf5.framework_dependency    kguiaddons libKF5GuiAddons
kf5.framework_dependency    kwidgetsaddons libKF5WidgetsAddons
kf5.framework_dependency    kconfigwidgets libKF5ConfigWidgets
kf5.framework_dependency    kitemviews libKF5ItemViews
kf5.framework_dependency    kiconthemes libKF5IconThemes
kf5.framework_dependency    kwindowsystem libKF5WindowSystem
kf5.framework_dependency    kcrash libKF5Crash
set kf5.kapidox_dep         path:bin/kgenapidox:kf5-kapidox
kf5.framework_dependency    kdbusaddons libKF5DBusAddons
kf5.framework_dependency    kdnssd libKF5DNSSD
kf5.framework_dependency    kidletime libKF5IdleTime
set kf5.kimageformats_dep   port:kf5-kimageformats
kf5.framework_dependency    kitemmodels libKF5ItemModels
kf5.framework_dependency    kplotting libKF5Plotting
set kf5.oxygen-icons_dep    path:share/icons/oxygen/index.theme:kf5-oxygen-icons
kf5.framework_dependency    solid libKF5Solid
kf5.framework_dependency    sonnet libKF5SonnetCore
kf5.framework_dependency    threadweaver libKF5ThreadWeaver
kf5.framework_dependency    kcompletion libKF5Completion
kf5.framework_dependency    kfilemetadata libKF5FileMetaData
kf5.framework_dependency    kjobwidgets libKF5JobWidgets
kf5.framework_dependency    knotifications libKF5Notifications
kf5.framework_dependency    kunitconversion libKF5UnitConversion
kf5.framework_dependency    kpackage libKF5Package
kf5.framework_dependency    kservice libKF5Service
kf5.framework_dependency    ktextwidgets libKF5TextWidgets
kf5.framework_dependency    kglobalaccel libKF5GlobalAccel
kf5.framework_dependency    kxmlgui libKF5XmlGui
kf5.framework_dependency    kbookmarks libKF5Bookmarks
kf5.framework_dependency    kwallet libKF5Wallet
kf5.framework_dependency    kio libKF5KIOCore
kf5.framework_dependency    baloo libKF5Baloo
kf5.framework_dependency    kdeclarative libKF5Declarative
kf5.framework_dependency    kcmutils libKF5KCMUtils

#########
# to install kf5-frameworkintegration:
#  kf5-attica
#  kf5-karchive
#  kf5-kauth
#  kf5-kbookmarks
#  kf5-kcodecs
#  kf5-kcompletion
#  kf5-kconfig
#  kf5-kconfigwidgets
#  kf5-kcoreaddons
#  kf5-kcrash
#  kf5-kdbusaddons
#  kf5-kdoctools
#  kf5-kglobalaccel
#  kf5-kguiaddons
#  kf5-ki18n
#  kf5-kiconthemes
#  kf5-kio
#  kf5-kitemviews
#  kf5-kjobwidgets
#  kf5-knotifications
#  kf5-kservice
#  kf5-ktextwidgets
#  kf5-kwallet
#  kf5-kwidgetsaddons
#  kf5-kwindowsystem
#  kf5-kxmlgui
#  kf5-solid
#  kf5-sonnet
# In this order:
# kf5-attica, kf5-karchive, kf5-kcoreaddons, kf5-kauth
# For kf5-kconfig: skipping org.macports.main (dry run)
# For kf5-kcodecs: skipping org.macports.main (dry run)
# For kf5-ki18n: skipping org.macports.main (dry run)
# For kf5-kdoctools: skipping org.macports.main (dry run)
# For kf5-kguiaddons: skipping org.macports.main (dry run)
# For kf5-kwidgetsaddons: skipping org.macports.main (dry run)
# For kf5-kconfigwidgets: skipping org.macports.main (dry run)
# For kf5-kitemviews: skipping org.macports.main (dry run)
# For kf5-kiconthemes: skipping org.macports.main (dry run)
# For kf5-kwindowsystem: skipping org.macports.main (dry run)
# For kf5-kcrash: skipping org.macports.main (dry run)
# For kf5-kdbusaddons: skipping org.macports.main (dry run)
# For kf5-kglobalaccel: skipping org.macports.main (dry run)
# For kf5-kcompletion: skipping org.macports.main (dry run)
# For kf5-kservice: skipping org.macports.main (dry run)
# For kf5-sonnet: skipping org.macports.main (dry run)
# For kf5-ktextwidgets: skipping org.macports.main (dry run)
# For kf5-kxmlgui: skipping org.macports.main (dry run)
# For kf5-kbookmarks: skipping org.macports.main (dry run)
# For kf5-kjobwidgets: skipping org.macports.main (dry run)
# For kf5-knotifications: skipping org.macports.main (dry run)
# For kf5-kwallet: skipping org.macports.main (dry run)
# For kf5-solid: skipping org.macports.main (dry run)
# For kf5-kio: skipping org.macports.main (dry run)
# For kf5-frameworkintegration: skipping org.macports.main (dry run)

# see also http://api.kde.org/frameworks-api/frameworks5-apidocs/attica/html/index.html

# kate: backspace-indents true; indent-pasted-text true; indent-width 4; keep-extra-spaces true; remove-trailing-spaces modified; replace-tabs true; replace-tabs-save true; syntax Tcl/Tk; tab-indents true; tab-width 4;
