# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4

# Copyright (c) 2015 The MacPorts Project
# Copyright (c) 2017-2019 RJVB
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
    ui_debug "Creating devport archive ${destroot}${dev::archdir}/${dev::archname} from \"${args}\""
    if {[catch {system -W ${destroot} "bsdtar -cjvf ${destroot}${dev::archdir}/${dev::archname} ${args}"} err]} {
        ui_error "Failure creating ${destroot}${dev::archdir}/${dev::archname} for ${args}: ${err}"
        file delete -force ${destroot}${dev::archdir}/${dev::archname}
    } else {
        ui_debug "Deleting archived \"${args}\""
        foreach a ${args} {
            file delete -force ${destroot}/${a}
        }
    }
}

# registers content that standard devports will contain
proc register_devport_standard_content {} {
    global subport destroot prefix name
    if {${subport} eq "${name}"} {
        ui_msg "--->  Transferring developer content to ${name}-dev"
        ui_debug "Finding and registering standard content for the devport"
        foreach h [glob -nocomplain ${destroot}${prefix}/include/*] {
            ui_debug "\theader: ${h}"
            devport_content-append [string map [list ${destroot} ""] ${h}]
        }
        foreach h [glob -nocomplain ${destroot}${prefix}/lib/lib*.a] {
            ui_debug "\tstatic library: ${h}"
            devport_content-append [string map [list ${destroot} ""] ${h}]
        }
        foreach h [glob -nocomplain ${destroot}${prefix}/lib/lib*.la] {
            ui_debug "\t.la library: ${h}"
            devport_content-append [string map [list ${destroot} ""] ${h}]
        }
        foreach h [glob -nocomplain ${destroot}${prefix}/lib/lib*.dylib] {
            if {![string match -nocase {lib*.[0-9.]*.dylib} [file tail ${h}]] && [file type ${h}] eq "link"} {
                ui_debug "\tMac shared linker library: ${h}"
                devport_content-append [string map [list ${destroot} ""] ${h}]
            }
        }
        foreach h [glob -nocomplain ${destroot}${prefix}/lib/lib*.so] {
            if {[file type ${h}] eq "link"} {
                ui_debug "\tstandard Unix shared linker library: ${h}"
                devport_content-append [string map [list ${destroot} ""] ${h}]
            }
        }
        foreach h [glob -nocomplain ${destroot}${prefix}/lib/pkgconfig/*] {
            ui_debug "\tpkg-config file: ${h}"
            devport_content-append [string map [list ${destroot} ""] ${h}]
        }
    }
}

proc append_to_devport_standard_content {args} {
    global subport destroot prefix name
    if {${subport} eq "${name}"} {
        foreach pattern ${args} {
            ui_debug "Finding and registering additional content for the devport: \"${pattern}\""
            foreach h [glob ${destroot}${pattern}] {
                ui_debug "\tmatching: ${h}"
                devport_content-append [string map [list ${destroot} ""] ${h}]
            }
        }
    }
}

# check for the presence and basic validity of the -dev port tarball,
# restoring the file from the main port install image if required.
# Main purpose: allow reinstalling the -dev port after uninstalling it,
# without having to reinstall/re-activate the main port.
# Warnings but no errors are raised if this fails.
proc restore_devport_tarball {baseport} {
    if {[file exists ${dev::archdir}/${dev::archname}]
        && [file size ${dev::archdir}/${dev::archname}] > 0} {
        return
    }
    if {![catch {set installed [lindex [registry_active ${baseport}] 0]}]} {
        set cVersion [lindex $installed 1]
        set cRevision [lindex $installed 2]
        set cVariants [lindex $installed 3]
        global name subport portdbpath os.platform os.major build_arch portarchivetype prefix
        set portimage "${portdbpath}/software/${baseport}/${baseport}-${cVersion}_${cRevision}${cVariants}.${os.platform}_${os.major}.${build_arch}.${portarchivetype}"
        if {[file exists ${portimage}]} {
            if {[catch {system -W ${prefix} "bsdtar -xf ${portimage} .${dev::archdir}/${dev::archname}"} err]} {
                ui_warn "Failure restoring ${dev::archdir}/${dev::archname}: ${err}"
            } elseif {![file exists ${dev::archdir}/${dev::archname}]
                || [file size ${dev::archdir}/${dev::archname}] == 0} {
                ui_warn "Failure restoring ${dev::archdir}/${dev::archname} - did you use sudo?"
                system "ls -l ${dev::archdir}/${dev::archname}*"
            }

        } else {
            ui_warn "Calculated port image \"${portimage}\" doesn't exist"
            if {[file exists ${portdbpath}/software/${baseport}]} {
                ui_warn "Image directory content:"
                system "ls -1 ${portdbpath}/software/${baseport}"
            }
        }
    } else {
        ui_warn "Cannot determine installed image name for ${baseport}"
    }
}

proc unpack_devport_content {} {
    global destroot prefix name subport
    if {[file exists ${dev::archdir}/${dev::archname}]
        && [file size ${dev::archdir}/${dev::archname}] > 0} {
        ui_debug "Unpacking \"${dev::archdir}/${dev::archname}\" for ${subport}"
        if {[catch {system -W ${destroot} "bsdtar -xvf ${dev::archdir}/${dev::archname}"} err]} {
            ui_error "Failure unpacking ${dev::archdir}/${dev::archname}: ${err}"
        }
    } else {
        ui_error "The port's content archive doesn't exists or is empty (${dev::archdir}/${dev::archname})!"
        return -code error "Missing or invalid content archive; try re-activating or reinstalling port:${name}"
    }
}

proc create_devport {dependency} {
    global name devport_description devport_long_description
    # just so we're clear that what port we're talking about (the main port):
    set baseport ${name}
    subport ${name}-dev {
        description     [join ${devport_description}]
        long_description [join ${devport_long_description}]
        depends_fetch
        depends_build
        depends_run
        depends_lib     ${dependency}
        depends_extract bin:bsdtar:libarchive
        installs_libs   yes
        supported_archs noarch
        distfiles
        fetch {}
        checksum {}
        extract {}
        use_configure   no
        patchfiles
        build           {}
        destroot {
            restore_devport_tarball ${baseport}
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

proc is_devport {} {
    global subport name
    return [eval {${subport} eq "${name}-dev"}]
}

proc is_mainport {} {
    global subport name
    return [expr {${subport} eq "${name}"}]
}
