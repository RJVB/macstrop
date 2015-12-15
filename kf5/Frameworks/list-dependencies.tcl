#!/opt/local/libexec/macports/bin/tclsh8.5
# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:filetype=tcl:et:sw=4:ts=4:sts=4
# $Id:$

# Create a namespace for some local variables
namespace eval portclient::progress {
    ##
    # Indicate whether the term::ansi::send tcllib package is available and was
    # imported. "yes", if the package is available, "no" otherwise.
    variable hasTermAnsiSend no
}

if {![catch {package require term::ansi::send}]} {
    set portclient::progress::hasTermAnsiSend yes
}

package require Tclx
package require macports
package require Pextlib 1.0

PortSystem          1.0
set kf5.framework   yes
PortGroup           kf5 1.1
