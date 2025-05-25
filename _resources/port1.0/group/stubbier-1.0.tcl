# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4

#===================================================================================================
#
# Portgroup to simplify declaration of stub ports/subports
# With RJVB's modifications to allow dis/re-enabling the pre- and post- phases
# NB: shares the `stub` namespace with the standard stub-1.0 PG!
#
#---------------------------------------------------------------------------------------------------
#
# Usage:
#   PortGroup           stubbier 1.0
#
#   name                my_name
#   version             my_version
#   revision            my_revision
#   categories          my_category
#   description         my_description
#   long_description    my_long_description
#
# Optional Declarations:
#   * license           - default: Permissive
#   * maintainers       - default: nomaintainer
#   * homepage          - default: empty
#
# PG Options:
#   * stub.subport_name - override subport name, for README location
#   * stub.readme       - whether to create README; defaults to yes
#
# PG Variables (to be set before including the PortGroup!):
#   * stub.fromHost_allow_pre_and_post 
#                       - set this to a True value in the Portfile to allow running
#                         pre- and post- blocks for +fromHost installs
#   * stub.disable_pre_and_post 
#                       - set this to a True value in the Portfile to disable
#                         pre- and post- blocks in all installs
#
#===================================================================================================

namespace eval stub {}

options stub.subport_name
default stub.subport_name ${subport}

options stub.readme
default stub.readme yes

proc stub::post_destroot {} {
    set create_readme [option stub.readme]
    if { ${create_readme} } {
        global destroot prefix

        set subport_name [option stub.subport_name]
        set docdir ${destroot}${prefix}/share/doc/${subport_name}
        xinstall -d ${docdir}
        system "echo ${subport_name} is a stub port > ${docdir}/README"
    }
}

if {[tbool stub.disable_pre_and_post] \
    || ([variant_exists fromHost] && [variant_isset fromHost] && ![tbool stub.fromHost_allow_pre_and_post])} {
    ui_debug "stubbier Portgroup defines stub::setup_stubbier to disable pre- and post- phases!"
    set setupFn "setup_stubbier"
} else {
    set setupFn "setup_stub"
}

proc stub::${setupFn} {} {
    global PortInfo

    if { ![info exists PortInfo(maintainers)] } {
        maintainers     nomaintainer
    }

    if { ![info exists PortInfo(homepage)] } {
        homepage
    }

    if { ![info exists PortInfo(license)] || ${PortInfo(license)} eq "unknown" } {
        license         Permissive
    }

    distfiles
    fetch.type          standard
    patchfiles
    use_autoreconf      no
    use_configure       no
    depends_lib
    # we're not building, so why add compiler build dependencies?!
    configure.compiler.add_deps no
    build {}
    # RJVB : run our bit of code in the destroot because "base"
    # has been modified not to run pre- and post- blocks if
    # procedure stub::stubbier (possibly this function) exists.
    destroot {
        stub::post_destroot
    }
}

# callback after port is parsed
port::register_callback stub::${setupFn}
