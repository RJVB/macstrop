# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4
# $Id: code-sign-1.0.tcl -1 2016-00-01 06:40:18Z gmail.com:rjvbertin $

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

# checks for the existence of a file etc/macports/codesigning.conf and read options
# from that file if it exists. If that provides a non-empty option `identity`, its
# contents will be used to sign the file given in the first argument. If the file also
# defines the `user` option, the signing operation will be run as that user. This is
# required unless the MacPorts user has the desired signing key in the keychain, or when
# using the ad hoc identify ("-").
# Additional arguments allow to override the defaults from codesigning.conf, e.g.
#
# codesign ${sub_prefix}/bin/debugserver lldb_codesign
#
# This procedure is supposed to be called from the post-activate phase. The procedure
# returns 0 in case of success, and 1 otherwise. This makes it possible to instruct
# the user, for instance to create the required key.
# Note that care should be taken (in a post-activate block) that the activation procedure
# doesn't abort.

proc codesign {app {sign_identity 0} {sign_user ""} {preserve ""}} {
    global prefix
#     if {[file exists ${prefix}/etc/macports/codesign-identity.tcl]} {
#         if {[catch {source "${prefix}/etc/macports/codesign-identity.tcl"} err]} {
#             ui_error "reading ${prefix}/etc/macports/codesign-identity.tcl: $err"
#             return -code error "Error reading ${prefix}/etc/macports/codesign-identity.tcl"
#         }
#     }
    set codesigning_conf "${prefix}/etc/macports/codesigning.conf"
    if {[file exists ${codesigning_conf}]} {
        set fd [open ${codesigning_conf} r]
        while {[gets $fd line] >= 0} {
            if {[regexp {^(\w+)([ \t]+(.*))?$} $line match option ignore val] == 1} {
                ui_msg "Option ${option} set to ${val}"
                set ${option} ${val}
            }
        }
        close $fd
    }
    if {${sign_identity} ne 0} {
        if {${sign_identity} ne "-" || ![info exists identity] || ${identity} eq ""} {
            set identity ${sign_identity}
            ui_info "Set sign identity from arguments; ${identity}"
        }
    }
    if {${sign_user} ne ""} {
        set user ${sign_user}
        ui_info "Set sign user from arguments; ${user}"
    }
    if {${preserve} ne ""} {
        set preserveoption "--preserve-metadata=${preserve}"
    } else {
        set preserveoption "--preserve-metadata"
    }
    platform darwin {
        if {[info exists identity] && (${identity} ne "")} {
            if {[file exists ${app}]} {
                if {[info exists user] && ${user} ne ""} {
                    set home [glob "~${user}"]
                    ui_info "Signing ${app} with ${identity} from ${user}'s keychains under HOME=${home}"
                    if {[catch {system "env HOME=${home} codesign -s ${identity} ${preserveoption} -f -vvv --deep ${app}"} err]} {
                        ui_error "Signing ${app} with ${identity} from ${user}'s keychains under HOME=${home}: ${err}"
                    } else {
                        return 0
                    }
                } else {
                    ui_info "Signing ${app} with ${identity}"
                    if {[catch {system "codesign -s ${identity} ${preserveoption} -f -vvv --deep ${app}"} err]} {
                        ui_error "Signing ${app} with ${identity}: ${err}"
                        ui_msg "You will probably need to set the user option to your own username in ${codesigning_conf}"
                    }
                }
            } else {
                ui_error "File ${app} cannot be signed because it doesn't exist"
            }
        }  else {
            ui_error "No signing identity given through the arguments or in ${codesigning_conf}"
        }
        return 1
    }
}
