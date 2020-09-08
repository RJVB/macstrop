#!/opt/local/bin/port-tclsh

package require Tclx
package require macports
package require Pextlib 1.0

array unset portinfo
set portname "qt5-kde-devel"

set argc [llength $::argv]
for {set i 0} {${i} < ${argc}} {incr i} {
    set arg "[lindex $::argv ${i}]"
    # process short arg(s)
    set opts [string range $arg 1 end]
    foreach c [split $opts {}] {
        switch -- $c {
            e {
                set ui_options(ports_env) yes
            }
            v {
                set ui_options(ports_verbose) yes
            }
            d {
                set ui_options(ports_debug) yes
                # debug implies verbose
                set ui_options(ports_verbose) yes
            }
            q {
                set ui_options(ports_quiet) yes
                # quiet implies noninteractive
                set ui_options(ports_noninteractive) yes
                # quiet implies no warning for outdated portindex
                set ui_options(ports_no_old_index_warning) 1
            }
            p {
                # ignore errors while processing within a command
                set ui_options(ports_processall) yes
            }
        }
    }
}

if {[catch {mportinit ui_options global_options global_variations} result]} {
    puts \$::errorInfo
        fatal "Failed to initialise MacPorts, \$result"
}

if {[catch {set mport [mportlookup $portname]} result]} {
    ui_debug $::errorInfo
    ui_error "lookup of portname $portname failed: $result"
    return ""
}
if {[llength $mport] < 2} {
    ui_error "Port $portname not found"
    return ""
}
array set portinfo [lindex $mport 1]
set porturl $portinfo(porturl)
set portname $portinfo(name)
set mport [mportopen ${porturl}]

set mpinterp [ditem_key ${mport} workername]

${mpinterp} eval {
    # naughty! :) Set subport to indicate to a port that always regenerates
    # the help collection on activation.
    set subport "qt5-assistant"
    qt5.rebuild_mp_qthelp_collection
}

mportclose ${mport}
