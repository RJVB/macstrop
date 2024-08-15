#!/usr/bin/env port-tclsh

set t0 [clock clicks -millisec]
puts -nonewline "Loading      MacPorts ..."
package require macports 1.0
package require registry 1.0
puts " done ([expr {([clock clicks -millisec]-$t0)/1000.}] sec)"

array set ui_options        {}
array set global_options    {}
array set global_variations {}

set ui_options(ports_debug) yes
set ui_options(ports_verbose) yes

### init
puts -nonewline "Initialising MacPorts ..."
flush stdout
set t0 [clock clicks -millisec]
mportinit ui_options global_options global_variations
puts " done ([expr {([clock clicks -millisec]-$t0)}] ms)"

ui_msg "MacPorts version [macports::version], registry version [registry::metadata get version]"

set maybe ""
if {[catch {registry::set_needs_vacuum}]} {
	ui_warn "Your MacPorts version doesn't allow to program a registry VACUUM operation"
	set maybe "maybe "
} else {
	ui_msg "Called registry::set_needs_vacuum"
}

puts -nonewline "Closing registry and ${maybe}performing vacuum ..."
flush stdout
set t0 [clock clicks -millisec]
mportshutdown
puts " done ([expr {([clock clicks -millisec]-$t0)}] ms)"
