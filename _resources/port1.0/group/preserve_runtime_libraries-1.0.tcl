# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4
# $Id:$

# Copyright (c) 2015 The MacPorts Project
# Copyright (c) 2016 R.J.V. Bertin
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
# PortGroup     preserve_runtime_libraries 1.0
#
# in the post-destroot, call preserve_libraries with the directory
# holding the libraries to preserve and a filename pattern. Example:
#
# post-destroot {
#   preserve_libraries ${prefix}/lib libwebp*.*.dylib
# }
#
# This will create a copy of the pre-existing libraries not installed
# by the current ${subport} to be stored in ${prefix}/${srcdir}/previous/${subport}
# with a symlink in ${prefix}/${srcdir} .
# Using a special repository makes it immediately clear which port a
# legacy runtime belongs to; the symlink makes it easy to test whether
# the copy is still used.

# Note that ports that depend on poppler via poppler-qt4-mac or
# poppler-qt5-mac do not need this trick to avoid rebuilding.


set preserve_runtime_library_dir "previous/${subport}"

proc preserve_libraries {srcdir patternlist} {
    global prefix subport destroot preserve_runtime_library_dir
    if {[variant_isset preserve_runtime_libraries]} {
        if {[file type ${srcdir}] eq "directory"} {
            set prevdir "${preserve_runtime_library_dir}"
            xinstall -m 755 -d ${destroot}${srcdir}/${prevdir}
            foreach pattern ${patternlist} {
                # first handle the preserved backups that already exist
                foreach l [glob -nocomplain ${srcdir}/${prevdir}/${pattern}] {
                    set lib [file tail ${l}]
                    set prevlib [file join ${destroot}${srcdir}/${prevdir} ${lib}]
                    if {![file exists ${prevlib}] && ![file exists ${destroot}${l}]} {
                        ui_debug "Preserving previous runtime shared library ${l} as ${prevlib}"
                        set perms [file attributes ${l} -permissions]
                        copy ${l} ${prevlib}
                        if {[file type ${prevlib}] ne "link"} {
                            file attributes ${prevlib} -permissions ${perms}
                        }
                        ln -s [file join ${prevdir} [file tail ${l}]] ${destroot}${srcdir}/${lib}
                    }
                }
                # now we can do the libraries to backup from ${prefix}/lib (srcdir) itself
                # any of those that are symlinks into ${prevdir} will be pruned because they
                # have already been handled.
                foreach l [glob -nocomplain ${srcdir}/${pattern}] {
                    set fport [registry_file_registered ${l}]
                    if {${fport} eq "${subport}"} {
                        set lib [file tail ${l}]
                        set prevlib [file join ${destroot}${srcdir}/${prevdir} ${lib}]
                        if {![file exists ${prevlib}] && ![file exists ${destroot}${l}]} {
                            ui_debug "Preserving previous runtime shared library ${l} as ${prevlib}"
                            set perms [file attributes ${l} -permissions]
                            copy ${l} ${prevlib}
                            if {[file type ${prevlib}] ne "link"} {
                                file attributes ${prevlib} -permissions ${perms}
                            }
                            ln -s [file join ${prevdir} [file tail ${l}]] ${destroot}${srcdir}/${lib}
                        }
                    } else {
                        ui_info "not preserving runtime library ${l} that belongs to port:${fport}"
                    }
                }
            }
        } else {
            ui_warn "Source for previous runtime libraries (${srcdir}) should be a directory"
        }
    } else {
        ui_debug "The preserve_runtime_libraries variant isn't set; ignoring the call to preserve_libraries"
    }
}

variant preserve_runtime_libraries description {Experimental variant that preserves the pre-existing runtime \
                                        libraries to ease the rebuilding load during upgrades.} {}

# kate: backspace-indents true; indent-pasted-text true; indent-width 4; keep-extra-spaces true; remove-trailing-spaces modified; replace-tabs true; replace-tabs-save true; syntax Tcl/Tk; tab-indents true; tab-width 4;

