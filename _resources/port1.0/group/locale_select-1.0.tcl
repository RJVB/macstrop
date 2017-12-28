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
# PortGroup     locale_select 1.0

# provide a configurable variant to install only the translations (locale files) of interest
# the selection is made in ${prefix}/etc/macports/locales.tcl (which should really become locales.conf);
# a template is provided in `port dir K5rameworks` .
variant langselect description "prune translations from ${prefix}/share/locale, leaving only those\
                                specified in ${prefix}/etc/macports/locales.tcl" {}

# optional directory holding Qt translations (.qm) (fully specified)
options langselect_qm_dir langselect_qm_basename
default langselect_qm_dir       {}
default langselect_qm_basename  {}

if {[variant_isset langselect]} {
    post-destroot {
        if {[file exists ${prefix}/etc/macports/locales.tcl] &&
            ([file exists ${destroot}${prefix}/share/locale] || [file exists [join ${langselect_qm_dir}]])
        } {
            if {[catch {source "${prefix}/etc/macports/locales.tcl"} err]} {
                ui_error "Error reading ${prefix}/etc/macports/locales.tcl: $err"
                return -code error "Error reading ${prefix}/etc/macports/locales.tcl"
            }
        }
        if {[info exists keep_languages]} {
            foreach l [glob -nocomplain ${destroot}${prefix}/share/locale/* ${destroot}${prefix}/share/doc/HTML/*] {
                set lang [file tail ${l}]
                if {[lsearch -exact ${keep_languages} ${lang}] eq "-1"} {
                    ui_info "rm ${l}"
                    file delete -force ${l}
                } else {
                    ui_debug "won't delete ${l} (${lang})"
                }
            }
            if {[file exists [join ${langselect_qm_dir}]]} {
                set lsqmdir [join ${langselect_qm_dir}]
                foreach l [glob -nocomplain ${lsqmdir}/*.qm] {
                    set lang [file rootname [file tail ${l}]]
                    if {${langselect_qm_basename} ne {}} {
                        set lang [string map [list "${langselect_qm_basename}_" ""] ${lang}]
                    }
                    if {[lsearch -exact ${keep_languages} ${lang}] eq "-1"} {
                        ui_info "rm ${l}"
                        file delete -force ${l}
                    } else {
                        ui_debug "won't delete ${l} (${lang})"
                    }
                }
            }
        }
    }
}

