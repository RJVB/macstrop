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
# PortGroup     code-sign 1.0

# checks for the existence of a file etc/macports/codesign-identity.tcl and includes
# that file if it exists. If that provides a non-empty variable ${identity}, its
# contents will be used to sign the files given in the argument(s), one by one.
# This procedure is supposed to be called from the post-activate phase.
proc codesign {first args} {
    global prefix
    # join ${first} and (the optional) ${args}
    set args [linsert $args[set list {}] 0 ${first}]
    if {[file exists ${prefix}/etc/macports/codesign-identity.tcl]} {
        if {[catch {source "${prefix}/etc/macports/codesign-identity.tcl"} err]} {
            ui_error "reading ${prefix}/etc/macports/codesign-identity.tcl: $err"
            return -code error "Error reading ${prefix}/etc/macports/codesign-identity.tcl"
        }
    }
    platform darwin {
        if {[info exists identity] && (${identity} ne "")} {
            foreach app ${args} {
                ui_info "Signing ${app}"
                if {[file exists ${app}]} {
                    if {[catch {system "codesign -s ${identity} --preserve-metadata -f -vvv --deep ${app}"} err]} {
                        ui_error "signing ${app}: ${err}"
                    }
                }
            }
        }  else {
            ui_error "${prefix}/etc/macports/codesign-identity.tcl does not define `identity`"
        }
    }
}