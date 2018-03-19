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
# PortGroup     compress_workdir 1.0
#

if {[info exists compress_workdir::currentportgroupdir]} {
    ui_debug "[dict get [info frame 0] file] has already been loaded"
    return
}

namespace eval compress_workdir {
    # our directory:
    variable currentportgroupdir [file dirname [dict get [info frame 0] file]]
}

options compress.build_dir
default compress.build_dir {${build.dir}}

platform darwin {
    # sadly we cannot rely on [file system <name>] to determine if we're on a
    # filesystem supporting HFS compression so we need to rely on the user.
    if {[info exist ::env(MACPORTS_COMPRESS_WORKDIR)] && $::env(MACPORTS_COMPRESS_WORKDIR)} {

        # Enable HFS compression if bsdtar is already installed
        if {[file exists ${prefix}/bin/bsdtar]} {
            extract.post_args    "| ${prefix}/bin/bsdtar -x --hfsCompression"
        }

        post-build {
            if {[file exists ${prefix}/bin/afsctool] && [file exists ${compress.build_dir}]} {
                ui_msg "--->  Compressing the build directory ..."
                if {${use_parallel_build}} {
                    set compjobs "-J${build.jobs}"
                } else {
                    set compjobs ""
                }
                if {[catch {system "${prefix}/bin/afsctool -cfvv -8 ${compjobs} -S ${compress.build_dir} 2>&1"} result context]} {
                    ui_info "Compression failed: ${result}, ${context}; port:afsctool is probably installed without support for parallel compression"
                    if {[catch {system "${prefix}/bin/afsctool -cfvv -8 ${compress.build_dir} 2>&1"} result context]} {
                        ui_error "Compression failed: ${result}, ${context}"
                    }
                } else {
                    ui_debug "Compressing ${compress.build_dir}: ${result}"
                    if {[tbool configure.ccache]} {
                        ui_msg "--->  Compressing the ccache directory ..."
                        if {![catch {system "${prefix}/bin/afsctool -cfvv -8 ${compjobs} -S ${ccache_dir} 2>&1"} result context]} {
                            ui_debug "Compressing ${ccache_dir}: ${result}"
                        }
                    }
                }
            }
        }

    }

}
