# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4

# Copyright (c) 2015 The MacPorts Project
# Copyright (c) 2017 RJVB
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
# PortGroup     devport 1.0

namespace eval dev {
    # it shouldn't be necessary to record variants in the archive name
    set archname ${name}@${version}-dev.tar.bz2
    # this could go into the software images directory
    set archdir ${prefix}/var/devcontent
}

options devport_content devport_description devport_long_description
default devport_content             ""
default devport_description         {"Development headers and libraries for ${name}"}
default devport_long_description    {"${long_description}\nThis installs the development headers and libraries."}

# create the online devport content archive
proc create_devport_content_archive {} {
    global destroot prefix
    set rawargs [option devport_content]
    set args ""
    # convert the arguments to local-relative:
    foreach a ${rawargs} {
        set args "${args} .${a}"
    }
    xinstall -m 755 -d ${destroot}${dev::archdir}
    if {[catch {system -W ${destroot} "bsdtar -cjvf ${destroot}${dev::archdir}/${dev::archname} ${args}"} err]} {
        ui_error "Failure creating ${destroot}${dev::archdir}/${dev::archname} for ${args}: ${err}"
        file delete -force ${destroot}${dev::archdir}/${dev::archname}
    } else {
        foreach a ${args} {
            file delete -force ${destroot}/${a}
        }
    }
}

# registers content that standard devports will contain
proc register_devport_standard_content {} {
    global subport destroot prefix name
    if {${subport} eq "${name}"} {
        foreach h [glob -nocomplain ${destroot}${prefix}/include/*] {
            devport_content-append [string map [list ${destroot} ""] ${h}]
        }
        foreach h [glob -nocomplain ${destroot}${prefix}/lib/lib*.a] {
            devport_content-append [string map [list ${destroot} ""] ${h}]
        }
        foreach h [glob -nocomplain ${destroot}${prefix}/lib/lib*.la] {
            devport_content-append [string map [list ${destroot} ""] ${h}]
        }
        foreach h [glob -nocomplain ${destroot}${prefix}/lib/lib*\[a-zA-Z\].so] {
            devport_content-append [string map [list ${destroot} ""] ${h}]
        }
        foreach h [glob -nocomplain ${destroot}${prefix}/lib/pkgconfig/*] {
            devport_content-append [string map [list ${destroot} ""] ${h}]
        }
    }
}

proc unpack_devport_content {} {
    global destroot prefix name
    if {[file exists ${dev::archdir}/${dev::archname}]} {
        if {[catch {system -W ${destroot} "bsdtar -xvf ${dev::archdir}/${dev::archname}"} err]} {
            ui_error "Failure unpacking ${dev::archdir}/${dev::archname}: ${err}"
        }
    } else {
        ui_error "The port's content archive doesn't exists (${dev::archdir}/${dev::archname})!"
        return -code error "Missing content archive; try re-activating or reinstalling port:${name}"
    }
}

proc create_devport {dependency} {
    global name devport_description devport_long_description
    subport ${name}-dev {
        description     [join ${devport_description}]
        long_description [join ${devport_long_description}]
        depends_lib-append \
                        ${dependency}
        installs_libs   yes
        supported_archs noarch
        distfiles
        fetch {}
        checksum {}
        extract {}
        use_configure   no
        patchfiles
        build {}
        destroot {
            unpack_devport_content
        }
        pre-activate {
            if {[file exists ${dev::archdir}/${dev::archname}]} {
                ui_info "${subport} is now installed, removing installed content archive ${dev::archdir}/${dev::archname}"
                file delete -force ${dev::archdir}/${dev::archname}
                # make sure the file exists to keep rev-upgrade happy
                # NB: this c/should be a symlink to the port's image tarball!
                system "touch ${dev::archdir}/${dev::archname}"
            }
        }
    }
}

