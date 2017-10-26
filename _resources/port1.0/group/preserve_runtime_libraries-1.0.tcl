# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4

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
            ui_debug "preserve_libraries ${srcdir} ${patternlist}"
            set fd -1
            if {![catch {set installed [lindex [registry_active ${subport}] 0]}]} {
                set cVersion [lindex $installed 1]
                set cRevision [lindex $installed 2]
                set cVariants [lindex $installed 3]
                set tocFName "${destroot}${srcdir}/${prevdir}/${subport}-${cVersion}-${cRevision}-${cVariants}.toc"
                if {![catch {set fd [open ${tocFName} "w"]} err]} {
                    puts ${fd} "# Libraries saved from port: ${subport}@${cVersion}_${cRevision}+${cVariants}:"
                    flush ${fd}
                    set tocStartSize [file size ${tocFName}]
                }
            }
            foreach pattern ${patternlist} {
                # first handle the preserved backups that already exist
                set existing_backups [glob -nocomplain ${srcdir}/${prevdir}/${pattern}]
                foreach l ${existing_backups} {
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
                foreach t [glob -nocomplain "${srcdir}/${prevdir}/${subport}-*.toc"] {
                    set toc [file tail ${t}]
                    set prevtoc [file join ${destroot}${srcdir}/${prevdir} ${toc}]
                    if {![file exists ${prevtoc}]} {
                        ui_debug "Preserving previous runtime shared library toc ${t}"
                        set perms [file attributes ${t} -permissions]
                        copy ${t} ${prevtoc}
                        if {[file type ${prevtoc}] ne "link"} {
                            file attributes ${prevtoc} -permissions ${perms}
                        }
                    }
                }
                # now we can do the libraries to backup from ${prefix}/lib (srcdir) itself
                # any of those that are symlinks into ${prevdir} will be pruned because they
                # have already been handled.
                set current_libs [glob -nocomplain ${srcdir}/${pattern}]
                foreach l ${current_libs} {
                    set fport [registry_file_registered ${l}]
                    # registry_file_registered returns "0" for files not belonging to a port
                    # we give the port author the favour of the doubt and backup the file anyway.
                    if {${fport} eq "${subport}" || ${fport} eq "0"} {
                        set lib [file tail ${l}]
                        set prevlib [file join ${destroot}${srcdir}/${prevdir} ${lib}]
                        if {![file exists ${prevlib}] && ![file exists ${destroot}${l}]} {
                            ui_debug "Preserving previous runtime shared library ${l} as ${prevlib}"
                            if {${fd} != -1 && [file type ${l}] ne "link"} {
                                puts ${fd} "${l}"
                            }
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
                if {"${existing_backups}" eq "" && "${current_libs}" eq ""} {
                    ui_info "preserve_libraries ${srcdir} \"${patternlist}\" preserved nothing for \"${pattern}\""
                    ui_info "\texisting backups found: \"${existing_backups}\""
                    ui_info "\tcurrent libraries: \"${current_libs}\""
                }
            }
            if {${fd} != -1} {
                close ${fd}
                if {[file size ${tocFName}] <= ${tocStartSize}} {
                    file delete ${tocFName}
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

