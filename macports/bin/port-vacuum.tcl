#!/usr/bin/env port-tclsh

package require macports 1.0
package require registry 1.0

array set ui_options        {}
array set global_options    {}
array set global_variations {}

set ui_options(ports_debug) yes
set ui_options(ports_verbose) yes

### init
mportinit ui_options global_options global_variations

ui_msg "MacPorts version [macports::version], registry version [registry::metadata get version]"

if {[catch {registry::set_needs_vacuum}]} {
	ui_warn "Your MacPorts version doesn't allow to program a registry VACUUM operation"
} else {
	ui_msg "Called registry::set_needs_vacuum"
}

mportshutdown
