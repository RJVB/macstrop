#!/usr/bin/env port-tclsh
# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#
# check if a port's destroot directory contains already installed files or (with -v) list new files or those
# that will no longer be available after upgrading (go "missing"; with -m).
#
# parts copied from Clemens Lang's port-check-distributable.tcl script and of course the `port` driver command
#
# everything else (c) 2017-2019 R.J.V. Bertin

set SCRIPTVERSION 0.3

array set portsSeen {}

# Begin

package require Thread
package require Tclx

set runner [thread::create -preserved [list thread::wait]]
thread::send $runner [list after 250 {puts stderr "Loading MacPorts..."}] timerID
package require macports
package require Pextlib 1.0
thread::send -async $runner [list after cancel $timerID]

proc printUsage {} {
    puts "Usage: $::argv0 \[-vV\] port-name\[s\]"
    puts "  -h    This help"
    puts "  -d    some debug output"
    puts "  -V    show version and MacPorts version being used"
    puts ""
    puts "Outputs [ba]sh syntax for setting env. variables to port dir info;"
    puts "  used by the port-redo-install-phase utility"
    puts "port-name\[s\] is the name of a port(s) to check"
    puts "port-name can also be the path to a destroot directory"
    puts "  (for checking projects that are not yet available as a port;"
    puts "   in this case it can be followed by a reference port name)"
}

set showVersion 0
set _WD_port {}
set portDir {}
set portFile {}
set bestGuessPortName {}

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

# taken from the `port` driver:
proc url_to_portname {url} {
    # Save directory and restore the directory, since mportopen changes it
    set savedir [pwd]
    set portname ""
    if {[catch {set ctx [mportopen $url]} result]} {
        ui_debug "$::errorInfo"
        ui_error "Can't map the URL '$url' to a port description file (\"${result}\")."
        ui_msg "Please verify that the directory and portfile syntax are correct."
    } else {
        array set portinfo [mportinfo $ctx]
        set portname $portinfo(name)
        mportclose $ctx
    }
    cd $savedir
    return $portname
}

proc port_workdir {portname} {
    # Operations on the port's directory and Portfile
    global env boot_env portDir portFile bestGuessPortName

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


    # Calculate portDir, porturl, and portfile from initial porturl
    set portDir [file normalize [macports::getportdir $porturl]]
    set porturl "file://${portDir}";    # Rebuild url so it's fully qualified
    set portFile "${portDir}/Portfile"
    # output the path to the port's work directory
    set workpath [macports::getportworkpath_from_portdir $portDir $portname]
    if {[file exists $workpath]} {
        # $workpath will be of the form $prefix/path/to..$mainport/$subport/work
        # where $subport is the official portName as defined in the portFile:
        set bestGuessPortName [file tail [file dirname ${workpath}]]
        return $workpath
    } else {
        set bestGuessPortName ${portname}
        return ""
    }
}

proc macports::normalise { filename } {
    set prefmap [list [file dirname [file normalize "${macports::prefix}/foo"]] ${macports::prefix}]
    return [string map ${prefmap} [file normalize $filename]]
}

set os.platform [string tolower $tcl_platform(os)]

thread::send $runner [list after 250 {puts stderr "Initialising MacPorts..."}] timerID
if {[catch {mportinit ui_options global_options global_variations} result]} {
    puts stderr $::errorInfo
    puts stderr "Failed to initialise MacPorts ($result)"
    exit -1
}
thread::send -async $runner [list after cancel $timerID]

thread::send $runner [list after 250 {puts stderr "Closing MacPorts..."}] timerID
if {$showVersion} {
    puts "Version ${SCRIPTVERSION}"
    puts "MacPorts version [macports::version]"
    mportshutdown
    exit 0
}

if {[llength $::argv] == 0} {
    puts "Error: missing port-name"
    printUsage
    mportshutdown
    exit 2
}
thread::send -async $runner [list after cancel $timerID]

set argc [llength $::argv]

for {set i 0} {${i} < ${argc}} {incr i} {
    set arg "[lindex $::argv ${i}]"
    set pWD ""
    if {[file exists ${arg}] && [file type ${arg}] eq "directory"} {
        set narg "[lindex $::argv [expr ${i} + 1]]"
        if {[file exists ${arg}/Portfile]} {
            set portDir [file normalize ${arg}]
            # from what I understand, [mportlookup] should support portDir or file://${portDir}
            # as well, but that doesn't work in this script?!
            # Just fall back to [url_to_portname], adapted from the `port` driver itself.
            set _WD_port [url_to_portname "file://${portDir}"]
            set portName ${_WD_port}
            set pWD [macports::getportworkpath_from_portdir ${portDir} ${_WD_port}]
            set portFile ${portDir}/Portfile
        } elseif {${narg} ne "" && (![file exists ${narg}] || [file type ${narg}] ne "directory")} {
            # user provided a port name
            set pWD [port_workdir ${narg}]
            set portName ${bestGuessPortName}
            set _WD_port ${portName}
            incr i
        } else {
            set portName ""
        }
    } elseif {${_WD_port} ne ${arg}} {
        set pWD [port_workdir ${arg}]
        set portName ${bestGuessPortName}
        set _WD_port ${portName}
    }
    if {${pWD} ne ""} {
        puts stdout "export portName=${portName}\nexport pWD=${pWD}\nexport _WD_port=${_WD_port}\nPORTDIR=${portDir}\npPFILE=${portFile}"
    } else {
        puts stderr "Cannot find a workdir for \"${arg}\""
    }
}

thread::send $runner [list after 250 {puts stderr "Closing MacPorts..."}] timerID
mportshutdown
