# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#=========================================================================================================
#
# This PortGroup adds a +fromPorts variant on platforms (i.e. not Darwin) where ports using this PortGroup
# expect to be able to take certain dependencies from the host. Setting the variant makes them take all
# dependencies from MacPorts/LinuxPorts/etc. instead, as they do under Darwin (= on Mac).
#=========================================================================================================

namespace eval fromPorts {}

if {${os.platform} eq "darwin"} {
    ui_debug "from_ports_variant: ${os.platform} does not need a variant 'fromPorts'"
} elseif { [variant_exists fromPorts] } {
    ui_debug "from_ports_variant: variant 'fromPorts' already exists"
} else {
    variant fromPorts conflicts fromHost description {Enable taking all dependencies from MacPorts} {}
}

# a simple function to hide a depspec declarations in an if/else expression
proc fromPorts::declare.all.dependencies {} {
    global os.platform
    if {${os.platform} eq "darwin" || ([variant_exists fromPorts] && [variant_isset fromPorts])} {
        ui_debug "fromPorts::declare.all.dependencies : platform=${os.platform} and/or +fromPorts=[variant_isset fromPorts]"
        return 1
    }
    return 0
}

# fromPorts::depends <fetch|extract|lib|build|run>[-append] depspec1 [depspec2 [...]]
#
# Conditional depspec declaration. On Darwin/Mac and/or if the +fromPorts variant is active,
# declare the provided dependencies. Otherwise, declare them if already installed, else expect
# to be able to take them from the host system.
# The 1st argument defines the dependency type (extract, fetch, lib, etc) and can take the form
# type-append (append the depspecs to the existing list) or type-delete (delete them, UNCONDITIONALLY);
# without suffix a simple `depends_${type} depspecs` is executed.
# NB: the procedure tries to call an as-yet inexistant function `registry_installed` which
# will return a possibly empty list of installed ports matching the pattern.
proc fromPorts::depends {type args} {
    global os.platform
    set dependstr "depends_${type}"
    set append [string last "-append" ${type}]
    set delete [string last "-delete" ${type}]
    # the shortest valid dependency type (lib) is 3 chars long
    if {${append} >= 3} {
        set type [string range ${type} 0 ${append}-1]
        set append 1
    } elseif {${delete} >= 3} {
        set type [string range ${type} 0 ${delete}-1]
        ui_debug "fromPorts::depends \"${type}\" : the delete operation is unconditional!"
        depends_${type}-delete {*}${args}
        return 1
    }
    if {${os.platform} eq "darwin" || ([variant_exists fromPorts] && [variant_isset fromPorts])} {
        ui_debug "fromPorts::depends \"${type}\" : platform=${os.platform} and/or +fromPorts=[variant_isset fromPorts]"
        ui_debug "depends_${type} {*}${args}"
        if {${append}} {
            depends_${type}-append {*}${args}
        } else {
            depends_${type} {*}${args}
        }
        return 1
    } else {
        foreach depspec ${args} {
            set lastcolon [string last ":" ${depspec}]
            if {${lastcolon} < 0} {
                set d ${depspec}
            } else {
                set d [string range ${depspec} [expr ${lastcolon} +1] end]
            }
            if {[catch {registry_active ${d}}]} {
                if {[catch {set installed_or_active [registry_installed ${d}]}]
                        || [llength ${installed_or_active}] <= 1} {
                    set installed_or_active 0
                } else {
                    set installed_or_active 1
                }
            } else {
                set installed_or_active 1
            }
            if {${installed_or_active}} {
                ui_debug "port:${d} is installed, adding depends_${type} ${depspec}"
                depends_${type}-append ${depspec}
            }
        }
    }
    return 0
}
