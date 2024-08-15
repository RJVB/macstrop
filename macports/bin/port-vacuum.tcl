#!/usr/bin/env port-tclsh

package require macports 1.0
package require registry 1.0

array set ui_options        {}
array set global_options    {}
array set global_variations {}

set ui_options(ports_debug) yes
set ui_options(ports_verbose) yes

### init
puts -nonewline "Initialising MacPorts ..."
flush stdout
mportinit ui_options global_options global_variations
puts " done"

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
mportshutdown
puts " done"
