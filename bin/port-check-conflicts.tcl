#!/usr/bin/env port-tclsh
# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#
# check if a port's destroot directory contains already installed files or (with -v) list new files
#
# parts copied from Clemens Lang's port-check-distributable.tcl script and of course the `port` driver command
#
# everything else (c) 2017 R.J.V. Bertin

set SCRIPTVERSION 0.1

array set portsSeen {}

proc printUsage {} {
    puts "Usage: $::argv0 \[-vV\] \[-t macports-tcl-path\] port-name\[s\]"
    puts "  -h    This help"
    puts "  -d    some debug output"
    puts "  -v    list new files (inVerse mode)"
    puts "  -V    show version and MacPorts version being used"
    puts ""
    puts "port-name\[s\] is the name of a port(s) to check"
    puts "port-name can also be the path to a destroot directory"
    puts "  (for checking projects that are not yet available as a port)"
}


# Begin

package require Tclx
package require macports
package require Pextlib 1.0

set macportsTclPath /Library/Tcl
set inverse 0
set showVersion 0
set _WD_port {}

array set ui_options        {}
array set global_options    {}
array set global_variations {}

while {[string index [lindex $::argv 0] 0] == "-" } {
    switch [string range [lindex $::argv 0] 1 end] {
        h {
            printUsage
            exit 0
        }
        d {
            set ui_options(ports_debug) yes
            # debug implies verbose
            set ui_options(ports_verbose) yes
        }
        t {
            if {[llength $::argv] < 2} {
                puts "-t needs a path"
                printUsage
                exit 2
            }
            set macportsTclPath [lindex $::argv 1]
            set ::argv [lrange $::argv 1 end]
        }
        v {
             set inverse 1
        }
        V {
            set showVersion 1
        }
        default {
            puts "Unknown option [lindex $::argv 0]"
            printUsage
            exit 2
        }
    }
    set ::argv [lrange $::argv 1 end]
}

proc port_workdir {portname} {
    # Operations on the port's directory and Portfile
    global env boot_env current_portdir

    set status 0

    array unset portinfo

    # Verify the portname, getting portinfo to map to a porturl
    if {[catch {set res [mportlookup $portname]} result]} {
        ui_debug $::errorInfo
        ui_error "lookup of portname $portname failed: $result"
        return ""
    }
    if {[llength $res] < 2} {
        ui_error "Port $portname not found"
        return ""
    }
    array set portinfo [lindex $res 1]
    set porturl $portinfo(porturl)
    set portname $portinfo(name)


    # Calculate portdir, porturl, and portfile from initial porturl
    set portdir [file normalize [macports::getportdir $porturl]]
    set porturl "file://${portdir}";    # Rebuild url so it's fully qualified
    set portfile "${portdir}/Portfile"
    # output the path to the port's work directory
    set workpath [macports::getportworkpath_from_portdir $portdir $portname]
    if {[file exists $workpath]} {
        return $workpath
    } else {
        return ""
    }
}

if {[catch {mportinit ui_options global_options global_variations} result]} {
    puts \$::errorInfo
        fatal "Failed to initialise MacPorts, \$result"
}

if {$showVersion} {
    puts "Version $SCRIPTVERSION"
    puts "MacPorts version [macports::version]"
    exit 0
}

if {[llength $::argv] == 0} {
    puts "Error: missing port-name"
    printUsage
    exit 2
}

foreach portName $::argv {
    set pWD ""
    if {[file exists ${portName}] && [file type ${portName}] eq "directory"} {
        # we're pointed to a directory
        set pWD ${portName}
    } elseif {${_WD_port} ne ${portName}} {
        set _WD_port ${portName}
        set pWD [port_workdir ${portName}]
    }
    if {${pWD} ne ""} {
        ui_debug "${portName}: ${pWD}"
        if {[file exists "${pWD}/destroot"]} {
            cd "${pWD}/destroot"
            set FILES [exec find . -type f]
            set InstalledDupsList {}
            set DestrootDupsList {}
            foreach f $FILES {
                set g [string range ${f} 1 end]
                if {[file exists "${g}"]} {
                    if {!${inverse}} {
                        set InstalledDupsList [lappend InstalledDupsList ${g}]
                        set DestrootDupsList [lappend DestrootDupsList ${f}]
                    }
                } elseif {${inverse}} {
                    puts "${g} doesn't exist yet"
                }
            }
        }
    }
}
