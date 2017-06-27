# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4

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
# PortGroup     qt5 1.0
#
# or
#
# set qt5.prefer_kde    1
# PortGroup             qt5 1.0

### testing testing testing ###
PortGroup           qt5-mac 1.0
return
###############################

# Check what Qt5 installation flavour already exists, or if not if the port calling us
# indicated a preference. If not, use the default/mainstream port:qt5 .
# Also use qt5-kde if we're on 10.6 because qt5-kde provides a fallback to Qt 5.3.2 on that OS version
if {([file exists ${prefix}/include/qt5/QtCore/QtCore]
        && ![info exists qt5.prefer_default]) || ${os.major} == 10} {
    # Qt5 has been installed through port:qt5-kde and is not the be reinstalled the other way
    ui_debug "Qt5 is provided by port:qt5-kde"
    PortGroup   qt5-kde 1.0
    set qt5.using_kde   yes
} elseif {[file exists ${prefix}/libexec/qt5/plugins]
        && [file type ${prefix}/libexec/qt5/plugins] eq "directory"} {
    # Qt5 has been installed through port:qt5 and is not to be reinstalled the other way
    ui_debug "Qt5 is provided by port:qt5"
    PortGroup   qt5-mac 1.0
    set qt5.using_kde   no
    if {[variant_isset qt5kde] || ([info exists qt5.prefer_kde] && [info exists building_qt5])} {
        if {[variant_isset qt5kde]} {
            ui_error "You cannot install ports with the +qt5kde variant when port:qt5 or one of its subports installed!"
        } else {
            ui_error "You cannot install a Qt5-KDE port with port:qt5 or one of its subports installed!"
        }
        pre-fetch {
            return -code error "Deactivate the conflicting port:qt5 (subports) first!"
        }
        pre-configure {
            return -code error "Deactivate the conflicting port:qt5 (subports) first!"
        }
    }
} elseif {[info exists qt5.prefer_kde] || [variant_isset qt5kde]} {
    # The calling port has indicated a preference and no Qt5 port is installed already
    ui_debug "Qt5 will be provided by port:qt5-kde, by request"
    PortGroup   qt5-kde 1.0
    set qt5.using_kde   yes
} else {
    # default fall-back to mainstream port:qt5
    ui_debug "Qt5 will be provided by port:qt5 (default)"
    PortGroup   qt5-mac 1.0
    set qt5.using_kde   no
}

if {!${qt5.using_kde}} {
    if {[info exists qt5.prefer_kde]} {
        # this is a port that prefers port:qt5-kde and thus expects most of Qt5 to be installed
        # through that single port rather than enumerate all components it depends on.
        depends_lib-append  port:qt5
    }
    if {![info exists qt_cmake_defines]} {
        # the Qt5 PortGroups used to define a variable that is no longer provided by qt5-mac-1.0.tcl;
        # set it to an empty value so that it can be referenced without side-effects.
        global qt_cmake_defines
        set qt_cmake_defines ""
    }
}

proc qt_branch {} {
    global version
    return [join [lrange [split ${version} .] 0 1] .]
}

# Ports that want to provide a universal variant need to use the muniversal PortGroup explicitly.
universal_variant no

global available_qt_versions
set available_qt_versions {
    qt5
    qt55
    qt56
    qt5-kde
    qt56-kde
}

# kate: backspace-indents true; indent-pasted-text true; indent-width 4; keep-extra-spaces true; remove-trailing-spaces modified; replace-tabs true; replace-tabs-save true; syntax Tcl/Tk; tab-indents true; tab-width 4;
