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
PortGroup               active_variants 1.1

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
#    + and a category for applications (kf5.category).
#
# otherwise the port will fail to build.
#
# Given the KDE release schedule with its linked versioning across all
# members of a "family" (applications, plasma, frameworks), an attempt
# is made to reduce the frequency of updates by providing "kf5.latest_*"
# variables which should never be anterior to the main version.
# Usage:
# After the regular command sequency leading up to the PortGroup include
# call kf5.use_latest kf5.release|kf5.version|kf5.plasma .
########################################################################

if { ![ info exists kf5.project ] } {
    ui_debug "kf5.project is not defined; falling back to \"manual\" configuration"
} else {
    name                kf5-${kf5.project}
}

# KF5 frameworks current version, which is the same for all frameworks
if {![info exists kf5.version]} {
    set kf5.version     5.20.0
    # kf5.latest_version is supposed to be used only in the KF5-Frameworks Portfile
    # when updating it to the new version (=kf5.latest_version).
    set kf5.latest_version \
                        5.20.0
}

# KF5 Applications version
if {![ info exists kf5.release ]} {
    set kf5.release     16.04.0
    set kf5.latest_release \
                        16.04.1
}

# KF5 Plasma version
if {![ info exists kf5.plasma ]} {
    set kf5.plasma      5.6.4
    set kf5.latest_plasma \
                        5.6.4
}

platforms               darwin linux
categories              kf5 kde devel
license                 GPL-2+

set kf5.branch           [join [lrange [split ${kf5.version} .] 0 1] .]

# Make sure to not use any already installed headers and libraries;
# these are set in CPATH and LIBRARY_PATH anyway.
configure.ldflags-delete  -L${prefix}/lib
configure.cppflags-delete -I${prefix}/include

# setup all KF5 ports to build in a separate directory from the source:
cmake.out_of_source     yes

if {![info exists kf5.dont_use_xz]} {
    use_xz              yes
}

set kf5.pyversion       2.7
set kf5.pybranch        [join [lrange [split ${kf5.pyversion} .] 0 1] ""]
if {${os.platform} eq "darwin"} {
    # this should probably become under control of a variant
    set kf5.pythondep   port:python27
    set kf5.pylibdir    ${frameworks_dir}/Python.framework/Versions/${kf5.pyversion}/lib/python${kf5.pyversion}
} elseif {${os.platform} eq "linux"} {
    # for personal use: don't add a python dependency.
    set kf5.pythondep   bin:python:python27
}

variant nativeQSP conflicts qspXDG description {use the native Apple-style QStandardPaths locations} {}

if {![file exists ${qt_includes_dir}/QtCore/qextstandardpaths.h]} {
    default_variants    +nativeQSP
}

if {![variant_isset nativeQSP]} {
    configure.cppflags-append \
                        -DQT_USE_EXTSTANDARDPATHS -DQT_EXTSTANDARDPATHS_XDG_DEFAULT=true
}

# A transitional procedure that adds definitions that are likely to become the default
proc kf5.use_QExtStandardPaths {} {
# 20160324 : remove payload because -DQT_EXTSTANDARDPATHS_XDG_DEFAULT=true is becoming the default
#     # 20160214 : switch from QStandardPaths to the experimental QExtStandardPaths
#     configure.cppflags-append \
#                     -DQT_USE_EXTSTANDARDPATHS
#     # configure QExtStandardPaths to use the QSP/XDG mode set by the QSP activator.
#     # alternatives are false (use native QSP) and true (use XDG-compliant QS).
#     # This will be set to "true" if it is decided to dump the QSP activator.
#     configure.cppflags-append \
#                     -DQT_EXTSTANDARDPATHS_XDG_DEFAULT=runtime
}

# TODO:
#
# Phonon added as library dependency here as most, if not all KDE
# programs current need it.  The phonon port, which includes this
# PortGroup overrides depends_lib, removing "port:phonon" to prevent a
# cyclic dependency
#depends_lib-append      port:phonon

# This is used by all KF5 frameworks
depends_lib-append      path:share/ECM/cmake/ECMConfig.cmake:kde-extra-cmake-modules

# configure.args-append   -G "\"CodeBlocks - Unix Makefiles\""

# Use directory set by qt5-kde or qt5-mac
configure.args-append   -DECM_MKSPECS_INSTALL_DIR=${qt_mkspecs_dir}

# set a best-compromise plugin destination directory, the one from Qt5.
# this is also what Kubuntu does, and possibly the only way to ensure that Qt5
# and KF5 find each other's (and their own...) plugins.
# The QML install location also has to be set
configure.args-append   -DPLUGIN_INSTALL_DIR=${qt_plugins_dir} \
                        -DKDE_INSTALL_QTPLUGINDIR=${qt_plugins_dir} \
                        -DQML_INSTALL_DIR=${qt_qml_dir}

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
    set kf5.libexec_dir ${prefix}/libexec/kde5
    configure.args-append \
                        -DBUNDLE_INSTALL_DIR=${kf5.applications_dir} \
                        -DCMAKE_DISABLE_FIND_PACKAGE_X11=ON \
                        -DAPPLE_SUPPRESS_X11_WARNING=ON \
                        -DCMAKE_INSTALL_LIBEXECDIR=${prefix}/libexec \
                        -DKDE_INSTALL_LIBEXECDIR=${kf5.libexec_dir}
} elseif {${os.platform} eq "linux"} {
    set kf5.applications_dir \
                        ${prefix}/bin
    set kf5.libexec_dir ${prefix}/lib/${build_arch}-linux-gnu/libexec
    configure.args-delete \
                        -DCMAKE_INSTALL_RPATH="${prefix}/lib"
    configure.args-append \
                        -DCMAKE_PREFIX_PATH=${prefix} \
                        -DCMAKE_INSTALL_RPATH="${prefix}/lib/${build_arch}-linux-gnu\;${prefix}/lib"
}
set kf5.docs_dir        ${prefix}/share/doc/kf5

set kf5.allow_docs_generation \
                        yes
variant docs description {build and install the documentation, for use with Qt's Assistant and KDevelop} {
    configure.args-delete \
                        -DBUILD_doc=OFF \
                        -DBUILD_docs=OFF
    if {${subport} ne "kf5-kapidox"} {
        if {${subport} ne "kf5-kdoctools"} {
            kf5.depends_frameworks \
                        kdoctools
        }
        if {[info exists kf5.allow_docs_generation]} {
            kf5.depends_build_frameworks \
                        kapidox
            post-destroot {
                ui_msg "--->  Generating documentation for ${subport}"
                # generate the documentation, working from ${build.dir}
                xinstall -m 755 -d ${destroot}${kf5.docs_dir}
                system -W ${build.dir} "kgenapidox --qhp --searchengine --api-searchbox \
                    --qtdoc-dir ${qt_docs_dir} --kdedoc-dir ${kf5.docs_dir} \
                    --qhelpgenerator ${qt_bins_dir}/qhelpgenerator ${worksrcpath}"
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
if {![variant_isset docs]} {
    # 20160325 : do this in the post-patch so patches around the targeted won't need to be
    # specific for +docs and -docs !
    post-patch {
        if {[file exists ${worksrcpath}/CMakeLists.txt]} {
            reinplace "/add_subdirectory.*(\[ ]*docs\[ \]*)/d" ${worksrcpath}/CMakeLists.txt
            reinplace "/add_subdirectory.*(\[ \]*doc\[ \]*)/d" ${worksrcpath}/CMakeLists.txt
        }
    }
}

if {${os.platform} eq "darwin"} {
   set kf5.libs_dir    ${prefix}/lib
   set kf5.libs_ext    dylib
} elseif {${os.platform} eq "linux"} {
   set kf5.libs_dir    ${prefix}/lib/${build_arch}-linux-gnu
   set kf5.libs_ext    so
}

if {![info exists kf5.framework] && ![info exists kf5.portingAid]} {
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

proc kf5.set_paths {} {
    upvar #0 kf5.virtualPath vp
    upvar #0 kf5.folder f
    global kf5.portingAid
    global kf5.framework
    global kf5.branch
    if { [ info exists kf5.portingAid ] } {
        set vp          "frameworks"
        set f           "frameworks/${kf5.branch}/portingAids"
    }

    if { [ info exists kf5.framework ] } {
        set vp          "frameworks"
        set f           "frameworks/${kf5.branch}"
    }
}
kf5.set_paths

proc kf5.is_framework {} {
    upvar #0 kf5.portingAid pa
    upvar #0 kf5.framework f
    unset pa
    set f yes
    kf5.set_paths
}

proc kf5.is_portingAid {} {
    upvar #0 kf5.portingAid pa
    upvar #0 kf5.framework f
    unset f
    set pa yes
    kf5.set_paths
}

proc kf5.set_project {project} {
    upvar #0 kf5.project p
    upvar #0 kf5.folder f
    global kf5.framework
    global kf5.portingAid
    global kf5.release
    global kf5.plasma
    global kf5.virtualPath
    global kf5.category
    global kf5.version
    global fetch.type
    global filespath
    global version
    set p ${project}
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
                    set f   "${kf5.virtualPath}/${kf5.plasma}"
#                     distname \
#                             ${project}-${kf5.plasma}
                    if {![info exists version]} {
                        version \
                            ${kf5.plasma}
                    }
                } else {
                    set f   "${kf5.virtualPath}/${kf5.release}/src"
#                     distname \
#                             ${project}-${kf5.release}
                    if {![info exists version]} {
                        version \
                            ${kf5.release}
                    }
                }
            }
        }
    } else {
        if {![info exists version]} {
            version         ${kf5.version}
        }
#         distname            ${project}-${kf5.version}
    }
    distname                ${project}-${version}
    if {[info exists kf5.category]} {
        homepage            http://www.kde.org/${kf5.virtualPath}/${kf5.category}/${project}
    } else {
        homepage            http://projects.kde.org/projects/${kf5.virtualPath}/${project}
    }
    if {${fetch.type} eq "git"} {
        if {[file exists ${filespath}/${project}-git/.git]} {
            git.url         ${filespath}/${project}-git
        } else {
            git.url         git://anongit.kde.org/${project}
        }
        distname            ${project}-${kf5.version}.git
    } else {
        master_sites        http://download.kde.org/stable/${f}
    }
}
if {[info exists kf5.project]} {
    kf5.set_project     ${kf5.project}
}

proc kf5.use_latest {lversion} {
    global kf5.latest_release kf5.latest_version kf5.latest_plasma kf5.project kf5.set_project kf5.branch
    global version
    upvar #0 kf5.version v
    upvar #0 kf5.release r
    upvar #0 kf5.plasma p
    upvar #0 kf5.branch b
    switch -nocase ${lversion} {
        kf5.version     {set v ${kf5.latest_version}}
        kf5.release     {set r ${kf5.latest_release}}
        kf5.plasma      {set p ${kf5.latest_plasma}}
        frameworks      {set v ${kf5.latest_version}}
        applications    {set r ${kf5.latest_release}}
        plasma          {set p ${kf5.latest_plasma}}
        default {
            ui_error "Illegal argument ${lversion} to kf5.use_latest"
            return -code error "Illegal argument to kf5.use_latest"
        }
    }
    # be sure that kf5.branch is set correctly too
    set b               [join [lrange [split ${v} .] 0 1] .]
    # and ditto for the paths.
    kf5.set_paths
    unset version
    if {[info exists kf5.project]} {
        kf5.set_project ${kf5.project}
    }
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

post-activate {
    if {[file exists ${prefix}/bin/kbuildsycoca5]} {
        ui_msg "--->  Updating KDE's global desktop file system configuration cache ..."
        system "${prefix}/bin/kbuildsycoca5 --global"
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
# This may be extended to provide path-style *runtime* dependencies on framework executables;
# kf5.framework_runtime_dependency{name {executable 0}} and kf5.depends_run_frameworks
# (which would have to add a library dependency if no executable dependency is defined).
proc kf5.framework_dependency {name {library 0} {soversion 5}} {
    upvar #0 kf5.${name}_dep dep
    upvar #0 kf5.${name}_lib lib
    if {${library} ne 0} {
        global os.platform build_arch
        if {${os.platform} eq "darwin"} {
            set kf5.lib_path    lib
            if {${soversion} ne ""} {
                set kf5.lib_ext 5.dylib
            } else {
                set kf5.lib_ext dylib
            }
        } elseif {${os.platform} eq "linux"} {
            set kf5.lib_path    lib/${build_arch}-linux-gnu
            if {${soversion} ne ""} {
                set kf5.lib_ext so.5
            } else {
                set kf5.lib_ext so
            }
        }
        set lib                 ${kf5.lib_path}/${library}.${kf5.lib_ext}
        set dep                 path:${lib}:kf5-${name}
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

proc kf5.has_translations {} {
    global kf5.pythondep
    global kf5.pyversion
    global prefix
    ui_debug "Adding gettext and ${kf5.pythondep} build dependencies because of KI18n"
    depends_build-append \
                        port:gettext \
                        ${kf5.pythondep}
    configure.args-append \
                        -DPYTHON_EXECUTABLE=${prefix}/bin/python${kf5.pyversion}
}

# kf5.depends_frameworks appends the ports corresponding to the KF5 Frameworks
# short names to depends_lib
# This procedure also adds the build dependencies that KI18n imposes
# Caution though: some KF5 packages will let the KI18n dependency be added
# through cmake's public link interface handling, rather than declaring an
# explicit dependency themselves that is listed in the printed summary.
proc kf5.depends_frameworks {first args} {
    # join ${first} and (the optional) ${args}
    set args [linsert $args[set list {}] 0 ${first}]
    foreach f ${args} {
        set kdep [kf5.framework_dependency ${f}]
        if {![catch {set nativeQSP [active_variants "${kdep}" nativeQSP]}]} {
            global subport
            if {${nativeQSP}} {
                # dependency is built for native QSP locations but the dependent port wants XDG locations
                if {([variant_isset qspXDG] || ![variant_isset nativeQSP])} {
                    ui_msg "Warning: ${subport} potential mismatch with kf5-${f}+nativeQSP"
                }
            } elseif {[variant_isset nativeQSP]} {
                # dependency is built for XDG QSP locations but the dependent port wants to use native locations
                ui_msg "Warning: ${subport}+nativeQSP potential mismatch with kf5-${f} (-nativeQSP)"
            }
        }
        depends_lib-append \
                        ${kdep}
        platform darwin {
            if {[lsearch {"baloo" "kactivities" "kdbusaddons" "kded" "kdelibs4support-devel" "kglobalaccel" "kio"
                            "kservice" "kwallet" "kwalletmanager" "plasma-framework"} ${f}] ne "-1"} {
                notes "
                    Don't forget that dbus needs to be started as the local\
                    user (not with sudo) before any KDE programs will launch.
                    To start it run the following command:
                     launchctl load -w /Library/LaunchAgents/org.freedesktop.dbus-session.plist
                    "
            }
        }
    }
    if {[lsearch -exact ${args} "ki18n"] ne "-1"} {
        kf5.has_translations
    }
}

# the equivalent to kf5.depends_frameworks for declaring build dependencies.
proc kf5.depends_build_frameworks {first args} {
    # join ${first} and (the optional) ${args}
    set args [linsert $args[set list {}] 0 ${first}]
    foreach f ${args} {
        depends_build-append \
                        [kf5.framework_dependency ${f}]
    }
    if {[lsearch -exact ${args} "ki18n"] ne "-1"} {
        kf5.has_translations
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
set kf5.oxygen-icons_dep    path:share/icons/oxygen/index.theme:kf5-oxygen-icons5
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
kf5.framework_dependency    kemoticons libKF5Emoticons
# this is really a framework...
kf5.framework_dependency    gpgmepp libKF5Gpgmepp
# kf5-kinit does install a library but it may not be the best choice as a dependency:
# hard to tell at this moment how many dependents actually use that rather than
# depending on one of the framework's executables.
kf5.framework_dependency    kinit libkdeinit5_klauncher ""
kf5.framework_dependency    kded libkdeinit5_kded5 ""
kf5.framework_dependency    kparts libKF5Parts
kf5.framework_dependency    kdewebkit libKF5WebKit
set kf5.kdesignerplugin_dep path:bin/kgendesignerplugin:kf5-kdesignerplugin
kf5.framework_dependency    kpty libKF5Pty
kf5.framework_dependency    kdelibs4support libKF5KDELibs4Support
kf5.framework_dependency    frameworkintegration libKF5Style
kf5.framework_dependency    kpeople libKF5People
kf5.framework_dependency    ktexteditor libKF5TextEditor
kf5.framework_dependency    kxmlrpcclient libKF5XmlRpcClient
kf5.framework_dependency    kactivities libKF5Activities
kf5.framework_dependency    kdesu libKF5Su
kf5.framework_dependency    knewstuff libKF5NewStuff
kf5.framework_dependency    knotifyconfig libKF5NotifyConfig
kf5.framework_dependency    plasma-framework libKF5Plasma
kf5.framework_dependency    kjs libKF5JS
kf5.framework_dependency    khtml libKF5KHtml
kf5.framework_dependency    krunner libKF5Runner

# not a framework; use the procedure to define the path-style dependency
kf5.framework_dependency    cli-tools libkdeinit5_kcmshell5 ""

# see also http://api.kde.org/frameworks-api/frameworks5-apidocs/attica/html/index.html

# provide links to icons from an installed theme in a format that is acceptable for ecm_add_app_icon
# iconDir : the full path to the icon theme directory (no trailing slash!)
# category : the category to which the icon belongs (ex: actions, or apps; no trailing slash!)
# iconName : the name of the icon file (must be a .png)
# destination: the full path to the destination directory
# see port:kf5-kdelibs4support (post-patch) for an example on how to use this.
proc kf5.link_icons {iconDir category iconName destination} {
    foreach icon [glob -nocomplain ${iconDir}/*/${category}/${iconName}] {
        set ifile [strsed ${icon} "s|${iconDir}/||"]
        set ifile [strsed ${ifile} "s|x\[0-9\]*/${category}/|-|"]
        if {![file exists ${destination}/${ifile}]} {
            ln -s ${icon} ${destination}/${ifile}
        }
    }
}

# rename icon files, for use with the kde4compat variant, in the post-destroot
# example:
# kf5.rename_icons ${destroot}${prefix}/share/icons/hicolor apps kate kate5
proc kf5.rename_icons {iconDir category iconOld iconNew {destination 0}} {
    if {${destination} eq "0"} {
        set destination ${iconDir}
    }
    foreach icon [glob -nocomplain ${iconDir}/*/${category}/${iconOld}.*] {
        set ipath [strsed ${icon} "s|${iconDir}/||"]
        # get the extention (png or svg or svgz)
        set ext [strsed ${ipath} "s|.*${iconOld}\.||"]
        # remove the original icon name
        set ipath [strsed ${ipath} "s|${iconOld}\.${ext}||"]
        if {[file exists ${icon}]} {
            # remove dest. file if already present
            file delete -force ${destination}/${ipath}${iconNew}.${ext}
            file rename ${icon} ${destination}/${ipath}${iconNew}.${ext}
        }
    }
}

# check how the named framework is installed, +qspXDG or
# (in some future) +nativeQSP
# use of this procedure requires the active_variants 1.1 PortGroup!
proc kf5.check_qspXDG {name} {
    if {![catch {set nativeQSP [active_variants "kf5-${name}" nativeQSP]}]
            && ![catch {set qspXDG [active_variants "kf5-${name}" qspXDG]}]} {
        if {${nativeQSP}} {
            ui_debug "kf5-${name} is installed +nativeQSP; check_qspXDG returns false"
            return no
        } elseif {${qspXDG}} {
            ui_debug "kf5-${name} is installed +qspQSP; check_qspXDG returns true"
            return yes
        }
    }
    return no
}

# create a wrapper script in ${prefix}/bin for an application bundle in kf5.applications_dir
proc kf5.add_app_wrapper {wrappername {bundlename ""} {bundleexec ""}} {
    global kf5.applications_dir destroot prefix os.platform
    if {${os.platform} eq "darwin"} {
        if {${bundlename} eq ""} {
            set bundlename ${wrappername}
        }
        if {${bundleexec} eq ""} {
            set bundleexec ${bundlename}
        }
        system "echo \"#!/bin/sh\nexport KDE_SESSION_VERSION=5\nexec \\\"${kf5.applications_dir}/${bundlename}.app/Contents/MacOS/${bundleexec}\\\" \\\"\\\$\@\\\"\" > ${destroot}${prefix}/bin/${wrappername}"
    } else {
        # no app bundles on this platform, but provide the same API by pretending there are.
        # If unset, use kf5.project to guess the exec. name because evidently we cannot
        # symlink ${wrappername} onto itself.
        if {${bundlename} eq ""} {
            set bundlename ${kf5.project}
        }
        if {${bundleexec} eq ""} {
            set bundleexec ${bundlename}
        }
        system "echo \"#!/bin/sh\nexport KDE_SESSION_VERSION=5\nexec \\\"${kf5.applications_dir}/${bundleexec}\\\" \\\"\\\$\@\\\"\" > ${destroot}${prefix}/bin/${wrappername}"
    }
    system "chmod 755 ${destroot}${prefix}/bin/${wrappername}"
}

# kate: backspace-indents true; indent-pasted-text true; indent-width 4; keep-extra-spaces true; remove-trailing-spaces modified; replace-tabs true; replace-tabs-save true; syntax Tcl/Tk; tab-indents true; tab-width 4;
