#!/opt/local/libexec/macports/bin/tclsh8.5

package require Tclx
package require macports
package require Pextlib
package require portutil

# Initialise mport
# This must be done following parse of global options, as some options are
# evaluated by mportinit.
if {[catch {mportinit ui_options global_options global_variations} result]} {
    global errorInfo
    puts "$errorInfo"
    fatal "Failed to initialise MacPorts, $result"
}

# open the port in corresponding to the directory we're living in
if {[catch {set mport [mportopen "file://[file dirname [info script]]"]} result]} {
    global errorInfo
    ui_debug $errorInfo
    ui_error "Unable to open port: $result"
    return 1
}

# array set portinfo [mportinfo ${mport}]
# parray portinfo

# get the interpreter that was used for evaluating code inside the Portfile
set portinterp [ditem_key ${mport} workername]

# One can export a number of variables of interest from that interpreter like so:
# set qt_cmake_module_dir [$portinterp eval set "qt_cmake_module_dir"]
# but it is much more practical to insert the code to run into the interpreter,
# and run it there.

# http://wiki.tcl.tk/15349
proc inject {name} {
    if {[info exists ::auto_index($name)]} {
        set body "# $::auto_index($name)\n"
    } else {
        set body ""
    }
    append body [info body $name]
    set argl {}
    foreach a [info args $name] {
        if {[info default $name $a def]} {
            lappend a $def
        }
        lappend argl $a
    }
    list proc $name $argl $body
}

# the code we want to run, written exactly like it would inside the Portfile:
proc fix_cmake_modules {} {
    global qt_cmake_module_dir qt_frameworks_dir qt_libs_dir qt_dir_rel destroot subport
    ui_msg ${qt_cmake_module_dir}
    ui_msg ${qt_frameworks_dir}
    ui_msg ${qt_libs_dir}
    ui_msg ${destroot}
    if {[info exists qt_cmake_module_dir]} {
        if {[file exists ${destroot}${qt_frameworks_dir}/cmake]} {
            set srcdir ${qt_frameworks_dir}
            # replace the *_install_prefix path with the correct path, but "take a detour" through ${qt_dir}
            # as an extra insurance and to show the expected Qt install location in case cmake ever finds
            # a .cmake script that doesn't below to this Qt5 port.
            set sedcmd "s|/../../../../|/../../../${qt_dir_rel}/|g"
        } elseif {[file exists ${destroot}${qt_libs_dir}/cmake]} {
            set srcdir ${qt_libs_dir}
            set sedcmd "s|/../../../../../|/../../../${qt_dir_rel}/../../|g"
        } else {
            ui_msg "${subport} destroot fixed already"
            return -code ok
        }
        foreach d [glob -tails -nocomplain -directory ${destroot}${srcdir}/cmake *] {
            xinstall -m 775 -d ${destroot}${qt_cmake_module_dir}/${d}
            foreach f [glob -nocomplain -directory ${destroot}${srcdir}/cmake/${d} *.cmake] {
                # ${qt_frameworks_dir} is  ${qt_dir}/Library/Frameworks while
                # ${qt_libs_dir}       is  ${qt_dir}/lib
                # unless modified, cmake files will point to a directory that is too high in the directory hierarchy
                reinplace ${sedcmd} ${f}
                file rename ${f} ${destroot}${qt_cmake_module_dir}/${d}/
            }
        }
    }
}

# inject the above procedure into $portinterp
$portinterp eval [inject "fix_cmake_modules"]
# evaluate the new procedure
$portinterp eval "fix_cmake_modules"

mportclose ${mport}
mportshutdown
