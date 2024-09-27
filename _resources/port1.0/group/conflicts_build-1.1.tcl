# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#
# This PortGroup implements the "conflicts_build" option, which lets ports
# specify that they would fail to build properly if certain other ports are
# installed at configure, build and/or destroot time. This is in contrast to
# the MacPorts built-in "conflicts" option, which is for indicating activation-
# time conflicts (i.e. ports that install files in the same locations).
#
# Ideally the conflicts_build option should be integrated into MacPorts base
# instead of being a PortGroup.


# conflicts_build: the list of ports with which this port conflicts at
# configure, build and/or destroot time.
options conflicts_build
default conflicts_build {}

options conflicts_destroot_too
default conflicts_destroot_too {yes}

options conflicts_build_badports
default conflicts_build_badports {}

proc conflicts_build._check_for_conflicting_ports {} {
    global conflicts_build subport conflicts_build_badports
    foreach badport ${conflicts_build} {
        if {![catch "registry_active ${badport}"]} {
            if {${subport} eq ${badport}} {
                ui_error "${subport} cannot be built while another version of ${badport} is active."
            } else {
                ui_error "${subport} cannot be built while ${badport} is active."
            }
            conflicts_build_badports-append ${badport}
        }
    }
    if {${conflicts_build_badports} ne {}} {
        ui_error "Please forcibly deactivate ${conflicts_build_badports}, e.g. by running:"
        ui_error ""
        ui_error "    sudo port -f deactivate ${conflicts_build_badports}"
        ui_error ""
        ui_error "Then try again."
        return -code error "${conflicts_build_badports} is/are active"
    }
}

pre-configure {
    conflicts_build._check_for_conflicting_ports
}

pre-build {
    conflicts_build._check_for_conflicting_ports
}

pre-destroot {
    if {[tbool conflicts_destroot_too]} {
        conflicts_build._check_for_conflicting_ports
    }
}
