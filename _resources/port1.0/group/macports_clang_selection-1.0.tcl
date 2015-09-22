# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
# $Id: qt5-1.0.tcl 113952 2015-06-11 16:30:53Z gmail.com:rjvbertin $

# Copyright (c) 2015 René J.V. Bertin
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
# This portgroup extends the whitelisting mechanism, de facto implementing
# a whitelist that behaves more like a true whitelist and less like a
# build dependency on the first compiler that is available for installation
# and not blacklisted.
# With the stock compiler.whitelist, the setting
#   compiler.whitelist clang macports-clang-3.7 macports-clang-3.6 macports-clang-3.5
#   compiler.blacklist {clang < 500}
# will install clang-3.7 if the Xcode clang is blacklisted (too old), even
# if the user has, say, macports-clang-3.5 installed. In fact, the mechanism
# causes the first allowed (non blacklisted) entry in the list to be used,
# whether that requires an install or not.
# A true whitelist mechanism would detect the installed, supported versions
# and pick the first among those, without imposing the installation of a newer
# version.
#
# Usage:
# PortGroup     compiler_whitelist_versions 1.0
#
# To obtain the desired behaviour from the example above, preconfigure the black
# and white lists:
#     compiler.whitelist clang
#     compiler.blacklist {clang < 500} macports-clang-3.4 macports-clang-3.3
# and then invoke
#     whitelist_macports_clang_versions {3.7 3.6 3.5}
# If none of the listed versions is installed, entries for all versions are added
# to the whitelist, and MacPorts' standard behaviour will result.
#
# Additionally, there is also a blacklist_macports_clang_versions function that
# does exactly what its name implies: it adds the specified versions to the
# compiler blacklist.
#     blacklist_macports_clang_versions {3.0 3.1 3.2 3.3 3.4}
# or
#     blacklist_macports_clang_versions {<= 3.4}
# These forms can be mixed ({< 3.2 3.4}) but it should be noted that range
# comparison only works for installed clang ports, currently. In other words,
# {<= 3.4} will blacklist an installed port:clang-3.3 but not macports-clang-2.0
# (which isn't installed because no such port exists; idem for a non-installed
# macports-clang-3.2).
#
# These functions can be seen as breaking the reproducable build principle and
# should thus be used sparingly and/or under special circumstances only.
# For this reason, another macro is provided: macports-clang-latest. This returns
# the latest macports-clang version known to exist for the host OS version, or
# else the current/latest stable release version (clang-3.6 as of sept. 2015).
# As such,
#     compiler.whitelist [macports-clang-latest]
# behaves like
#     compiler.whitelist clang
# and should be equally acceptable under the reproducable build principle.

proc macports-clang-latest {} {
    global os.major
    global os.platform
    if {${os.platform} eq "darwin"} {
        if {${os.major} < 10} {
            ui_msg "macports-clang-latest is untested on OS X 10.5 and earlier"
            return "macports-clang-3.4"
        }
        switch ${os.major} {
            10 {
                # latest version known to build
                ui_debug "Returning last-known-to-build macports-clang-3.5"
                return "macports-clang-3.5"
            }
            default {
                # latest stable release version in MacPorts (20150922)
                ui_debug "Returning current latest stable release version macports-clang-3.6"
                return "macports-clang-3.6"
            }
        }
    } else {
        # latest stable release version in MacPorts (20150922)
        ui_debug "Not OS X: returning current latest stable release version macports-clang-3.6"
        return "macports-clang-3.6"
    }
}

proc whitelist_macports_clang_versions {versions} {
    global prefix
    global compiler.whitelist
    global compiler.blacklist
    # starting with the one-but-newest macports-clang in the version list, check if it is
    # installed and blacklist the other values so that the automatic selection mechanism
    # will select the installed whitelisted version.
    set whitelist {}
    set car [lindex ${versions} 0]
    if {[file exists ${prefix}/libexec/llvm-${car}/bin/clang]} {
        ui_debug "whitelisting macports-clang-${car} because it exists, and skipping the remaining versions"
        compiler.whitelist-append macports-clang-${car}
        return
    }
    foreach white [lrange ${versions} 1 end] {
        if {[file exists ${prefix}/libexec/llvm-${white}/bin/clang]} {
            ui_debug "whitelisting macports-clang-${white}"
            set whitelist [linsert ${whitelist}[set whitelist {}] 0 macports-clang-${white}]
            foreach grey ${versions} {
                if {${grey} ne ${white} && ![file exists ${prefix}/libexec/llvm-${grey}/bin/clang]} {
                    # this is probably redundant
                    ui_debug "blacklisting macports-clang-${grey} because it is not installed and v${white} is present"
                    compiler.blacklist-append   macports-clang-${grey}
                }
            }
        }
    }
    if {[llength ${whitelist}] > 0} {
        ui_debug "Appending ${whitelist} to the compiler.whitelist"
        compiler.whitelist-append ${whitelist}
    } else {
        ui_debug "whitelisting all macports-clang from ${versions} because none are installed"
        foreach white ${versions} {
            compiler.whitelist-append macports-clang-${white}
        }
    }
}

proc blacklist_macports_clang_versions {versions} {
    global prefix
    global compiler.whitelist
    global compiler.blacklist
    while {[llength ${versions}] > 0} {
        set version [lindex ${versions} 0]
        switch -regexp ${version} {
            [0-9.]+ {
                ui_debug "blacklisting macports-clang-${version} whether it's installed or not"
                compiler.blacklist-append macports-clang-${version}
                set versions [lrange ${versions} 1 end]
            }
            default {
                set comp ${version}
                set refversion [lindex ${versions} 1]
                # check all installed llvm directories:
                foreach l [glob -nocomplain -tails -path ${prefix}/libexec/llvm -- -*] {
                    # not really required to check if llvm-${version}/bin/clang exists, here
                    # ${l} will be of the form "llvm-3.6"
                    set version [lindex [split ${l} "-"] 1]
                    if {[expr [vercmp ${version} ${refversion}] ${comp} 0]} {
                        ui_debug "blacklisting macports-clang-${version} because it is installed and ${comp} ${refversion}"
                        compiler.blacklist-append macports-clang-${version}
                    }
                }
                set versions [lrange ${versions} 2 end]
            }
        }
    }
    ui_debug "compiler.blacklist=${compiler.blacklist}"
}

# kate: backspace-indents true; indent-pasted-text true; indent-width 4; keep-extra-spaces true; remove-trailing-spaces modified; replace-tabs true; replace-tabs-save true; syntax Tcl/Tk; tab-indents true; tab-width 4;
