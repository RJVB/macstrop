# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4
# $Id: kf5-1.1.tcl 134210 2015-03-20 06:40:18Z mk@macports.org $

# Copyright (c) 2015 The MacPorts Project
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
# Usage:
# PortGroup     kf5 1.1

PortGroup               cmake 1.1
set qt5.prefer_kde      1
PortGroup               qt5 1.0
PortGroup               active_variants 1.1

if {![info exists qt5.using_kde] || !${qt5.using_kde}} {
    ui_warn "It is strongly advised to install KF5 ports against port:qt5-kde or port:qt5-kde-devel."
}

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
# call kf5.use_latest kf5.release|kf5.version|kf5.plasma
# or
# call kf5.use_latest applications|frameworks|plasma .
########################################################################

namespace eval kf5 {
    # our directory:
    set currentportgroupdir [file dirname [dict get [info frame 0] file]]
}

if {[file exists ${kf5::currentportgroupdir}/compress_workdir-1.0.tcl]} {
    PortGroup           compress_workdir 1.0
}

if { ![ info exists kf5.project ] } {
    ui_debug "kf5.project is not defined; falling back to \"manual\" configuration"
} else {
    name                kf5-${kf5.project}
}

# KF5 frameworks current version, which is the same for all frameworks
if {![info exists kf5.version]} {
    set kf5.version     5.27.0
    # kf5.latest_version is supposed to be used only in the KF5-Frameworks Portfile
    # when updating it to the new version (=kf5.latest_version).
    set kf5.latest_version \
                        5.27.0
}

# KF5 Applications version
if {![ info exists kf5.release ]} {
    set kf5.release     16.08.2
    set kf5.latest_release \
                        16.08.3
}

# KF5 Plasma version
if {![ info exists kf5.plasma ]} {
    set kf5.plasma      5.8.2
    set kf5.latest_plasma \
                        5.8.2
}

platforms               darwin linux
categories              kf5 kde devel
license                 GPL-2+

set kf5.branch           [join [lrange [split ${kf5.version} .] 0 1] .]

# Make sure to not use any already installed headers and libraries;
# these are set in CPATH and LIBRARY_PATH anyway.
configure.ldflags-delete  -L${prefix}/lib
configure.cppflags-delete -I${prefix}/include

if {![info exists kf5.dont_use_xz]} {
    use_xz              yes
}

# kf5.py* variable definitions (now kf5::py* namespaced variables) were
# here; moved to kf5-frameworks-1.0.tcl

platform darwin {
    variant nativeQSP description {use the native Apple-style QStandardPaths locations} {}

    if {![file exists ${qt_includes_dir}/QtCore/qextstandardpaths.h]} {
        default_variants    +nativeQSP
    }

    if {![variant_isset nativeQSP]} {
        configure.cppflags-append \
                        -DQT_USE_EXTSTANDARDPATHS -DQT_EXTSTANDARDPATHS_ALT_DEFAULT=true
    }
}

# A transitional procedure that adds definitions that are likely to become the default
proc kf5.use_QExtStandardPaths {} {
    if {[variant_isset nativeQSP]} {
        ui_error "Port ${subport} shouldn't call kf5.use_QExtStandardPaths with +nativeQSP"
        return -code error "kf5.use_QExtStandardPaths shouldn't be called"
    } else {
        ui_msg "kf5.use_QExtStandardPaths is obsolete"
    }
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
configure.args-append   -DECM_MKSPECS_INSTALL_DIR=${qt_mkspecs_dir}/modules

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
                        -DBUILD_SHARED_LIBS=ON \
                        -DCMAKE_STRIP:FILEPATH=/bin/echo
if {${os.platform} eq "darwin"} {
    set kf5.applications_dir \
                        ${applications_dir}/KF5
    set kf5.libexec_dir ${prefix}/libexec/kde5
    configure.args-append \
                        -DBUNDLE_INSTALL_DIR=${kf5.applications_dir} \
                        -DCMAKE_DISABLE_FIND_PACKAGE_X11=ON \
                        -DAPPLE_SUPPRESS_X11_WARNING=ON \
                        -DCMAKE_INSTALL_LIBEXECDIR=${prefix}/libexec \
                        -DKDE_INSTALL_LIBEXECDIR=${kf5.libexec_dir} \
                        -DCMAKE_MACOSX_RPATH=ON
    # 20160914: may need to set -DCMAKE_POLICY_DEFAULT_CMP0042=NEW
} elseif {${os.platform} eq "linux"} {
    set kf5.applications_dir \
                        ${prefix}/bin
    set kf5.libexec_dir ${prefix}/lib/${build_arch}-linux-gnu/libexec
#     configure.args-delete \
#                         -DCMAKE_INSTALL_RPATH="${prefix}/lib"
#     configure.args-append \
#                         -DCMAKE_PREFIX_PATH=${prefix} \
#                         -DCMAKE_INSTALL_RPATH="${prefix}/lib/${build_arch}-linux-gnu\;${prefix}/lib"
    cmake.install_rpath-prepend \
                        ${prefix}/lib/${build_arch}-linux-gnu
    configure.args-append \
                        -DCMAKE_PREFIX_PATH=${prefix}
}
configure.args-append   -DSYSCONF_INSTALL_DIR="${prefix}/etc"
set kf5.docs_dir        ${prefix}/share/doc/kf5

options kf5.allow_docs_generation
default kf5.allow_docs_generation yes

variant docs description {build and install the API documentation, for use with Qt's Assistant and KDevelop} {
    configure.args-delete \
                        -DBUILD_doc=OFF \
                        -DBUILD_docs=OFF
    if {${subport} ne "kf5-kapidox" && ${subport} ne "kf5-kapidox-devel"} {
        if {![info exists kf5.framework]} {
            kf5.depends_build_frameworks \
                        kdoctools
        }
        if {[info exists kf5.allow_docs_generation] && ${kf5.allow_docs_generation}} {
            if {[info exists kf5.framework]} {
                # KF5 frameworks are more or less guaranteed to have a metainfo.yaml file
                # which is required for newer kapidox versions. We could check for
                # the existence of that file, but that would mean depending on both
                # versions of the framework.
                kf5.depends_build_frameworks \
                        kapidox
            } else {
                # other software will be processed by an older KApiDox version,
                # installed under the name kf5-kgenapidox
                kf5.depends_build_frameworks \
                        kgenapidox
            }
            post-build {
                ui_msg "--->  Generating documentation for ${subport} (this can take a while)"
                # generate the documentation, working from ${build.dir}
                file delete -force ${workpath}/apidocs
                xinstall -m 755 -d ${workpath}/apidocs
                # this appears to be necessary, sometimes:
                system "chmod 755 ${workpath}/apidocs"
                if {[info exists kf5.framework]} {
                    if {[catch {system -W ${build.dir} "kapidox_generate --qhp --searchengine --api-searchbox \
                        --qtdoc-dir ${qt_docs_dir} --qhelpgenerator ${qt_bins_dir}/qhelpgenerator ${worksrcpath}"} result context]} {
                        ui_msg "Failure generating documentation: ${result}"
                    }
                    # after creating the destination, copy all generated qch documentation to it
                    foreach doc [glob -nocomplain ${build.dir}/frameworks/*/qch/*.qch ${build.dir}/*/qch/*.qch] {
                        if {[file tail ${doc}] ne "None.qch"} {
                            xinstall -m 644 ${doc} ${workpath}/apidocs/
                        }
                    }
                    file delete -force ${build.dir}/${kf5.framework}-${version}
                } else {
                    system -W ${build.dir} "kgenapidox --qhp --searchengine --api-searchbox \
                        --qtdoc-dir ${qt_docs_dir} --kdedoc-dir ${kf5.docs_dir} \
                        --qhelpgenerator ${qt_bins_dir}/qhelpgenerator ${worksrcpath}"
                    # after creating the destination, copy all generated qch documentation to it
                    foreach doc [glob -nocomplain ${build.dir}/apidocs/qch/*.qch] {
                        if {[file tail ${doc}] ne "None.qch"} {
                            xinstall -m 644 ${doc} ${workpath}/apidocs/
                        }
                    }
                    file delete -force ${build.dir}/apidocs
                }
            }
            post-destroot {
                xinstall -m 755 -d ${destroot}${kf5.docs_dir}
                # this appears to be necessary, sometimes:
                system "chmod 755 ${destroot}${kf5.docs_dir}"
                foreach doc [glob -nocomplain ${workpath}/apidocs/*.qch] {
                    xinstall -m 644 ${doc} ${destroot}${kf5.docs_dir}
                }
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
            reinplace "/ADD_SUBDIRECTORY.*(\[ ]*docs\[ \]*)/d" ${worksrcpath}/CMakeLists.txt
            reinplace "/ADD_SUBDIRECTORY.*(\[ \]*doc\[ \]*)/d" ${worksrcpath}/CMakeLists.txt
        }
    }
}
platform darwin {
    post-destroot {
        if {![variant_isset nativeQSP] && (${supported_archs} ne "noarch")} {
            if {[file exists ${build.dir}/CMakeCache.txt] || [file exists ${build.dir}/Makefile]} {
                ui_msg "--->  Checking ${subport} for QSP ALT mode ..."
                if {[catch {system "fgrep 'DQT_USE_EXTSTANDARDPATHS -DQT_EXTSTANDARDPATHS_ALT_DEFAULT=true' -R ${build.dir} --include=CMake* --include=Makefile --include=*.make 2>&1"} result context]} {
                    ui_msg "QSP ALT mode  check failed: ${result}, ${context}"
                } else {
                    ui_info "QSP ALT mode check: OK (${result})"
                }
            } else {
                ui_info "####  Cannot check ${subport} for QSP ALT mode (not a CMake project)."
            }
        }
    }
}

namespace eval kf5 {
    variable libs_ext
}
if {${os.platform} eq "darwin"} {
    set kf5.libs_dir    ${prefix}/lib
    set kf5::libs_ext   dylib
} elseif {${os.platform} eq "linux"} {
    set kf5.libs_dir    ${prefix}/lib/${build_arch}-linux-gnu
    set kf5::libs_ext   so
}

if {![info exists kf5.framework] && ![info exists kf5.portingAid]} {
    # explicitly define certain headers and libraries, to avoid
    # conflicts with those installed into system paths by the user.
    configure.args-append \
                        -DDOCBOOKXSL_DIR=${prefix}/share/xsl/docbook-xsl \
                        -DGETTEXT_INCLUDE_DIR=${prefix}/include \
                        -DGETTEXT_LIBRARY=${prefix}/lib/libgettextlib.${kf5::libs_ext} \
                        -DGIF_INCLUDE_DIR=${prefix}/include \
                        -DGIF_LIBRARY=${prefix}/lib/libgif.${kf5::libs_ext} \
                        -DJASPER_INCLUDE_DIR=${prefix}/include \
                        -DJASPER_LIBRARY=${prefix}/lib/libjasper.${kf5::libs_ext} \
                        -DJPEG_INCLUDE_DIR=${prefix}/include \
                        -DJPEG_LIBRARY=${prefix}/lib/libjpeg.${kf5::libs_ext} \
                        -DLBER_LIBRARIES=${prefix}/lib/liblber.${kf5::libs_ext} \
                        -DLDAP_INCLUDE_DIR=${prefix}/include \
                        -DLDAP_LIBRARIES=${prefix}/lib/libldap.${kf5::libs_ext} \
                        -DLIBEXSLT_INCLUDE_DIR=${prefix}/include \
                        -DLIBEXSLT_LIBRARIES=${prefix}/lib/libexslt.${kf5::libs_ext} \
                        -DLIBICALSS_LIBRARY=${prefix}/lib/libicalss.${kf5::libs_ext} \
                        -DLIBICAL_INCLUDE_DIRS=${prefix}/include \
                        -DLIBICAL_LIBRARY=${prefix}/lib/libical.${kf5::libs_ext} \
                        -DLIBINTL_INCLUDE_DIR=${prefix}/include \
                        -DLIBINTL_LIBRARY=${prefix}/lib/libintl.${kf5::libs_ext} \
                        -DLIBXML2_INCLUDE_DIR=${prefix}/include/libxml2 \
                        -DLIBXML2_LIBRARIES=${prefix}/lib/libxml2.${kf5::libs_ext} \
                        -DLIBXML2_XMLLINT_EXECUTABLE=${prefix}/bin/xmllint \
                        -DLIBXSLT_INCLUDE_DIR=${prefix}/include \
                        -DLIBXSLT_LIBRARIES=${prefix}/lib/libxslt.${kf5::libs_ext}
#                         -DOPENAL_INCLUDE_DIR=/System/Library/Frameworks/OpenAL.framework/Headers \
#                         -DOPENAL_LIBRARY=/System/Library/Frameworks/OpenAL.framework
#                         -DPNG_INCLUDE_DIR=${prefix}/include \
#                         -DPNG_PNG_INCLUDE_DIR=${prefix}/include \
#                         -DPNG_LIBRARY=${prefix}/lib/libpng.${kf5::libs_ext} \
#                         -DTIFF_INCLUDE_DIR=${prefix}/include \
#                         -DTIFF_LIBRARY=${prefix}/lib/libtiff.${kf5::libs_ext}
}

proc kf5.set_paths {} {
    upvar #0 kf5.virtualPath vp
    upvar #0 kf5.folder f
    global kf5.portingAid
    global kf5.framework
    global kf5.branch
    if { [info exists kf5.portingAid] } {
        set vp          "frameworks"
        set f           "frameworks/${kf5.branch}/portingAids"
    }

    if { [info exists kf5.framework] } {
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

namespace eval kf5 {
    set cat ""
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
    # get rid of the currently registered category:
    categories-delete       ${kf5::cat}
    if { ![info exists kf5.framework] && ![info exists kf5.portingAid] } {
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
                    if {![info exists version]} {
                        version \
                            ${kf5.plasma}
                    }
                    set kf5::cat "Plasma5"
                } else {
                    set f   "${kf5.virtualPath}/${kf5.release}/src"
                    if {![info exists version]} {
                        version \
                            ${kf5.release}
                    }
                    livecheck.url \
                                http://download.kde.org/stable/${kf5.virtualPath}
                    livecheck.regex \
                                (\\d+\\.\\d+\\.\\d)
                    set kf5::cat "Applications"
                }
            }
        }
    } else {
        if {![info exists version]} {
            version         ${kf5.version}
        }
    }
    categories-append       ${kf5::cat}
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

### kf5.depends_frameworks and the framework dependency defs used to be inlined here
### include the dedicated file in which they are housed now, but only if it
### resides in the same directory as ourselves.
### Do NOT impose this restriction if we're reading a copy stored in the registry!
if {[string first "registry/portgroup" ${kf5::currentportgroupdir}] < 0} {
    if {![file exists ${kf5::currentportgroupdir}/kf5-frameworks-1.0.tcl]} {
        ui_error "The kf5 1.0 and kf5-frameworks 1.0 PortGroups should reside in the same directory"
        return -code error "KF5 PortGroup installation error"
    }
} else {
    ui_debug "Reading a registry copy of the KF5 PortGroup from ${kf5::currentportgroupdir}"
}
PortGroup kf5-frameworks 1.0
# TODO: raise error if inclusion failed

# not a framework; use the procedure to define the path-style dependency
kf5::framework_dependency    cli-tools libkdeinit5_kcmshell5 ""

# see also http://api.kde.org/frameworks-api/frameworks5-apidocs/attica/html/index.html

# provide links to icons from an installed theme in a format that is acceptable for ecm_add_app_icon
# iconDir : the full path to the icon theme directory (no trailing slash!)
# category : the category to which the icon belongs (ex: actions, or apps; no trailing slash!)
# iconName : the name of the icon file (must be a .png)
# destination: the full path to the destination directory
# see port:kf5-kdelibs4support (post-patch) for an example on how to use this.
proc kf5.link_icons {iconDir category iconName destination} {
    set iconlist [glob -nocomplain ${iconDir}/*/${category}/${iconName}]
    if {${iconlist} eq ""} {
        set iconlist [glob -nocomplain ${iconDir}/base/*/${category}/${iconName}]
        set iconDir ${iconDir}/base
    }
    foreach icon ${iconlist} {
        set ifile [strsed ${icon} "s|${iconDir}/||"]
        set ifile [strsed ${ifile} "s|x\[0-9\]*/${category}/|-|"]
        if {![file exists ${destination}/${ifile}]} {
            ui_info "${icon} -> ${destination}/${ifile}"
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
options kf5.wrapper_env_additions
default kf5.wrapper_env_additions ""
proc kf5.add_app_wrapper {wrappername {bundlename ""} {bundleexec ""}} {
    global kf5.applications_dir os.platform kf5.wrapper_env_additions

    qt5.wrapper_env_additions "[join ${kf5.wrapper_env_additions}]"
    if {${os.platform} eq "darwin"} {
        if {${bundlename} eq ""} {
            set bundlename ${wrappername}
        }
        if {${bundleexec} eq ""} {
            set bundleexec ${bundlename}
        }
    } else {
        global kf5.project qt_libs_dir
        # no app bundles on this platform, but provide the same API by pretending there are.
        # If unset, use kf5.project to guess the exec. name because evidently we cannot
        # symlink ${wrappername} onto itself.
        if {${bundlename} eq ""} {
            set bundlename ${kf5.project}
        }
        if {${bundleexec} eq ""} {
            set bundleexec ${bundlename}
        }
    }
    qt5.add_app_wrapper ${wrappername} ${bundlename} ${bundleexec} ${kf5.applications_dir}
}

# procedure to record a conflict with a KDE4 port if kde4compat isn't active
proc kf5.kde4compat {{kde4port ""}} {
    global subport
    if {[variant_exists kde4compat] && ![variant_isset kde4compat]} {
        if {${kde4port} eq ""} {
            if {[string first "kf5-" ${subport}] >= 0} {
                conflicts-append \
                        [string range ${subport} 4 end]
            }
        } else {
            conflicts-append \
                        ${kde4port}
        }
    }
}

# this should hopefully be temporary: redefine the platform statement so it takes an "else" clause
proc platform {os args} {
    global os.platform os.subplatform os.arch os.major

    set len [llength $args]
    if {$len < 1} {
        return -code error "Malformed platform specification"
    }
    if {[lindex $args end-1] eq "else"} {
        set code [lindex $args end-2]
        set altcode [lindex $args end]
        set consumed 3
    } else {
        set code [lindex $args end]
        set altcode ""
        set consumed 1
    }

    foreach arg [lrange $args 0 end-$consumed]  {
        if {[regexp {(^[0-9]+$)} $arg match result]} {
            set release $result
        } elseif {[regexp {([a-zA-Z0-9]*)} $arg match result]} {
            set arch $result
        }
    }

    set match 0
    # 'os' could be a platform or an arch when it's alone
    if {$len == 2 && ($os == ${os.platform} || $os == ${os.subplatform} || $os == ${os.arch})} {
        set match 1
    } elseif {($os == ${os.platform} || $os == ${os.subplatform})
              && (![info exists release] || ${os.major} == $release)
              && (![info exists arch] || ${os.arch} == $arch)} {
        set match 1
    }

    # Execute the code if this platform matches the platform we're on
    if {$match} {
        uplevel 1 $code
    } elseif {${altcode} ne ""} {
        uplevel 1 $altcode
    }
}

if {[info procs qt5.depends_component] eq ""} {
    # apparently the qt5-kde PortGroup is not being used,
    # provide a simplified local copy of qt5.depends_component;
    # a procedure for declaring dependencies on Qt5 components, which will expand them
    # into the appropriate subports for the Qt5 flavour installed (presumably port:qt5)
    # e.g. qt5.depends_component qtbase qtsvg qtdeclarative
    proc qt5.depends_component {first args} {
        # join ${first} and (the optional) ${args}
        set args [linsert $args[set list {}] 0 ${first}]
        set qt5pprefix "qt5"
        foreach comp ${args} {
            if {${comp} eq "qt5"} {
                depends_lib-append port:${qt5pprefix}
            } else {
                set portname "${qt5pprefix}-${comp}"
                depends_lib-append port:${portname}
            }
        }
    }
}

proc kf5.depends_qt5_components {first args} {
    global qt5.using_kde
    set args [linsert $args[set list {}] 0 ${first}]
    if {![info exists qt5.using_kde] || !${qt5.using_kde}} {
        qt5.depends_component ${args}
    } else {
        foreach comp ${args} {
            if {${comp} eq "qtwebkit" || ${comp} eq "qtwebengine"} {
                qt5.depends_component ${comp}
            }
        }
    }
}

if {[variant_exists debug] && [variant_isset debug]} {
    configure.optflags-append   -fno-limit-debug-info
    configure.cflags-append     -fno-limit-debug-info
    configure.cxxflags-append   -fno-limit-debug-info
}

# kate: backspace-indents true; indent-pasted-text true; indent-width 4; keep-extra-spaces true; remove-trailing-spaces modified; replace-tabs true; replace-tabs-save true; syntax Tcl/Tk; tab-indents true; tab-width 4;
