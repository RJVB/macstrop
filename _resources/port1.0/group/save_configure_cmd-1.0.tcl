# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4

namespace eval configure {
    variable redirect_configure_output no
    variable statevar no
    proc logfile {} {
        if {[catch {set fn [get_logfile]}]} {
            return ""
        } else {
            return $fn
        }
    }
}

proc configure.save_configure_cmd {{save_log_too ""}} {
    namespace upvar ::configure configure_cmd_saved statevar
    if {${configure::statevar}} {
        ui_debug "configure.save_configure_cmd already called"
        return;
    }
    set configure::statevar yes

    if {![info exists configure.args]} {
        configure.args-append
    }
    if {![info exists configure.post_args]} {
        configure.post_args-append
    }
    if {${save_log_too} ne ""} {
        pre-configure {
            if {${configure::redirect_configure_output} || [configure::logfile] eq ""} {
                configure.pre_args-prepend "-cf '${configure.cmd} "
                configure.post_args-append "|& tee ${workpath}/.macports.${subport}.configure.log'"
                configure.cmd "/bin/csh"
                ui_debug "configure command set to `${configure.cmd} ${configure.pre_args} ${configure.args} ${configure.post_args}`"
            }
        }
        if {${save_log_too} eq "install log"} {
            post-destroot {
                set docdir ${destroot}${prefix}/share/doc/${subport}
                xinstall -m 755 -d ${docdir}
                foreach cfile [glob -nocomplain ${workpath}/.macports.${subport}.configure*] {
                    xinstall -m 644 ${cfile} ${docdir}/[string map {".macports" "macports"} [file tail ${cfile}]]
                }
            }
        }
    }
    post-configure {
        if {![catch {set fd [open "${workpath}/.macports.${subport}.configure.cmd" "w"]} err]} {
            foreach var [array names ::env] {
                puts ${fd} "${var}=$::env(${var})"
            }
            puts ${fd} "[join [lrange [split ${configure.env} " "] 0 end] "\n"]"
            # the following variables are no longer set in the environment at this point:
            puts ${fd} "CPP=\"${configure.cpp}\""
            # these are particularly relevant because referenced in the configure.pre_args:
            puts ${fd} "CC=\"${configure.cc}\""
            puts ${fd} "CXX=\"${configure.cxx}\""
            if {${configure.objcxx} ne ${configure.cxx}} {
                puts ${fd} "OBJCXX=\"${configure.objcxx}\""
            }
            puts ${fd} "CFLAGS=\"${configure.cflags}\""
            puts ${fd} "CXXFLAGS=\"${configure.cxxflags}\""
            if {${configure.objcflags} ne ${configure.cflags}} {
                puts ${fd} "OBJCFLAGS=\"${configure.objcflags}\""
            }
            if {${configure.objcxxflags} ne ${configure.cxxflags}} {
                puts ${fd} "OBJCXXFLAGS=\"${configure.objcxxflags}\""
            }
            puts ${fd} "LDFLAGS=\"${configure.ldflags}\""
            puts ${fd} "# Commandline configure options:"
            if {${configure.optflags} ne ""} {
                puts -nonewline ${fd} " configure.optflags=\"${configure.optflags}\""
            }
            if {${configure.compiler} ne ""} {
                puts -nonewline ${fd} " configure.compiler=\"${configure.compiler}\""
            }
            if {${configureccache} ne ""} {
                puts -nonewline ${fd} " configureccache=\"${configureccache}\""
            }
            if {${configure.cxx_stdlib} ne ""} {
                puts -nonewline ${fd} " configure.cxx_stdlib=\"${configure.cxx_stdlib}\""
            }
            puts ${fd} ""
            puts ${fd} "\ncd ${worksrcpath}"
            puts ${fd} "${configure.cmd} [join ${configure.pre_args}] [join ${configure.args}] [join ${configure.post_args}]"
            close ${fd}
            unset fd
        }
        set logfile [configure::logfile]
        if {!${configure::redirect_configure_output} && ${logfile} ne ""} {
            ui_debug "Filtering configure log from ${logfile})"
            if {![catch {flush_logfile} err]} {
                ui_debug "Flushed file ${logfile}"
            } else {
                ui_debug "Couldn't flush ${logfile}: $err"
            }
            exec sync
            catch {exec fgrep ":info:configure " ${logfile} | sed "s/:info:configure //g" > ${workpath}/.macports.${subport}.configure.log}
        }
    }
}
