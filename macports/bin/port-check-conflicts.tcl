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

package require Tclx
package require macports
package require Pextlib 1.0

package require fileutil::traverse

proc printUsage {} {
    puts "Usage: $::argv0 \[-vV\] \[-t macports-tcl-path\] port-name\[s\]"
    puts "  -h    This help"
    puts "  -d    some debug output"
    puts "  -m    list files that will go missing (present in the active named port, not in the version-to-be-installed)"
    puts "  -n    list files that are newer (can be combined with -v)"
    puts "  -N    like -n but do an `ls -l` of the compared files (the new file will show up as \".${macports::prefix}/XXX\")"
    puts "  -q    quiet mode"
    puts "  -T    take datestamp of newer but unchanged headerfiles (under a /include/ directory)"
    puts "        from the installed files (requires -n)"
    puts "  -v    list new files (inVerse mode)"
    puts "  -V    show version and MacPorts version being used"
    puts ""
    puts "port-name\[s\] is the name of a port(s) to check"
    puts "port-name can also be the path to a destroot directory"
    puts "  (for checking projects that are not yet available as a port;"
    puts "   in this case it can be followed by a reference port name)"
}

# fileutil::traverse filter:
proc trAccept {path} {
    set ftype [file type ${path}]
    if {![string equal ${ftype} "directory"]} {
        ui_debug "${path} : accepting ${ftype}"
        return 1
    } else {
        return 0
    }
}
# don't follow symlinks:
proc noLinks {path} {
    if {[string equal [file type ${path}] link]} {
        set target [file link ${path}]
        if {[string equal [file type ${target}] "directory"]} {
            ui_debug "Not following symlink ${path} to directory ${target}"
            return 0
        }
    }
    return 1
}

fileutil::traverse Trawler . -filter trAccept -prefilter noLinks

# extend a command with a new subcommand
proc extend {cmd body} {
    if {![namespace exists ${cmd}]} {
        set wrapper [string map [list %C $cmd %B $body] {
            namespace eval %C {}
            rename %C %C::%C
            namespace eval %C {
                proc _unknown {junk subc args} {
                    return [list %C::%C $subc]
                }
                namespace ensemble create -unknown %C::_unknown
            }
        }]
    }

    append wrapper [string map [list %C $cmd %B $body] {
        namespace eval %C {
            %B
            namespace export -clear *
        }
    }]
    uplevel 1 $wrapper
}

extend string {
    proc cat args {
        join $args ""
    }
}

set macportsTclPath /Library/Tcl
set inverse 0
set missing 0
set newer 0
set listnewer 0
set showVersion 0
set touchHeaders 0
set _WD_port {}

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
        q {
            set ui_options(ports_quiet) yes
        }
        t {
            if {[llength $::argv] < 2} {
                puts "-t needs a path"
                printUsage
                exit 2
            }
            set macportsTclPath [lindex $::argv 1]
            set ::argv [lrange $::argv 1 end]
        }
        m {
            if {!${inverse} && !${newer}} {
                 set missing 1
            } else {
                puts "-m is mutually exclusive with -n|N and -v"
                exit 2
            }
        }
        n {
            if {!${missing}} {
                 set newer 1
                 set listnewer 0
            } else {
                puts "-m, -n|N and -v are mutually exclusive"
                exit 2
            }
        }
        N {
            if {!${missing}} {
                 set newer 1
                 set listnewer 1
            } else {
                puts "-m, -n|N and -v are mutually exclusive"
                exit 2
            }
        }
        T {
            if {${newer}} {
                 set touchHeaders 1
            } else {
                puts "-T requires -n"
                exit 2
            }
        }
        v {
            if {!${missing}} {
                set inverse 1
            } else {
                puts "-m and -v are mutually exclusive"
                exit 2
            }
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

proc port_workdir {portname} {
    # Operations on the port's directory and Portfile
    global env boot_env current_portdir

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


    # Calculate portdir, porturl, and portfile from initial porturl
    set portdir [file normalize [macports::getportdir $porturl]]
    set porturl "file://${portdir}";    # Rebuild url so it's fully qualified
    set portfile "${portdir}/Portfile"
    # output the path to the port's work directory
    set workpath [macports::getportworkpath_from_portdir $portdir $portname]
    if {[file exists $workpath]} {
        return $workpath
    } else {
        return ""
    }
}

proc macports::normalise { filename } {
    set prefmap [list [file dirname [file normalize "${macports::prefix}/foo"]] ${macports::prefix}]
    return [string map ${prefmap} [file normalize $filename]]
}

set os.platform [string tolower $tcl_platform(os)]
set checkdpkg ""

proc port_provides { fileNames } {
    global os.platform checkdpkg
    # In this case, portname is going to be used for the filename... since
    # that is the first argument we expect... perhaps there is a better way
    # to do this?
    if { ![llength $fileNames] } {
        ui_error "Please specify a filename to check which port provides that file."
        return 1
    }
    foreach filename $fileNames {
        set file [macports::normalise $filename]
        if {[file exists $file] || ![catch {file type $file}]} {
            if {![file isdirectory $file] || [file type $file] eq "link"} {
                set port [registry::file_registered $file]
                if { $port != 0 } {
                    dict set providers "${filename}" "${port}"
                } else {
                    set checkdpkg "${checkdpkg} ${file}"
                    dict set providers "${filename}" "not_by_MacPorts"
                }
            } else {
                dict set providers "${filename}" "is_a_directory"
            }
        } else {
            dict set providers "${filename}" "does_not_exist"
        }
    }
    registry::close_file_map

    return ${providers}
}

proc port_contents { portname } {
    if { ![catch {set ilist [registry::installed $portname]} result] } {
        # set portname again since the one we were passed may not have had the correct case
        set portname [lindex $ilist 0 0]
    }
    set files [registry::port_registered $portname]
    if { $files != 0 } {
        if { [llength $files] > 0 } {
            return ${files}
        } else {
            ui_notice "Port $portname does not contain any files or is not active."
        }
    } else {
        ui_notice "Port $portname is not installed."
    }
    registry::close_file_map

    return {}
}

proc message { filename message } {
    if {${filename} ne ""} {
        regsub -all {[ \r\t\n]+} ${filename} "" gg
        if {${filename} ne ${gg}} {
            puts -nonewline "\"${filename}\""
        } else {
            puts -nonewline "${filename}"
        }
        if {[file exists ${filename}] && [file type ${filename}] ne "file"} {
            puts -nonewline " ([file type ${filename}])"
        }
        if {![macports::ui_isset ports_quiet]} {
            puts -nonewline " "
        }
    }
    if {![macports::ui_isset ports_quiet]} {
        puts "${message}"
    } else {
        puts ""
    }
}

# see https://stackoverflow.com/a/29289660/1460868
proc fileEqual {file1 file2} {
    if {[file size $file1] == [file size $file2]} {
        if {[catch {set f1 [open $file1]} cresult]} {
            puts $::errorInfo
            return 0
        }
        fconfigure $f1 -translation binary
        if {[catch {set f2 [open $file2]} cresult]} {
            puts $::errorInfo
            return 0
        }
        fconfigure $f2 -translation binary
        while {![info exist same]} {
            if {[read $f1 4096] ne [read $f2 4096]} {
                set same 0
            } elseif {[eof $f1]} {
                # The same if we got to EOF at the same time
                set same [eof $f2]
            } elseif {[eof $f2]} {
                set same 0
            }
        }
        close $f1
        close $f2
        return $same
    } else {
        return 0
    }
}

if {[catch {mportinit ui_options global_options global_variations} result]} {
    puts \$::errorInfo
        fatal "Failed to initialise MacPorts, \$result"
}

if {$showVersion} {
    puts "Version ${SCRIPTVERSION}"
    puts "MacPorts version [macports::version]"
    exit 0
}

if {[llength $::argv] == 0} {
    puts "Error: missing port-name"
    printUsage
    exit 2
}

set argc [llength $::argv]

for {set i 0} {${i} < ${argc}} {incr i} {
    set arg "[lindex $::argv ${i}]"
    set pWD ""
    set OK 0
    if {[file exists ${arg}] && [file type ${arg}] eq "directory"} {
        set narg "[lindex $::argv [expr ${i} + 1]]"
        if {${narg} ne "" && (![file exists ${narg}] || [file type ${narg}] ne "directory")} {
            set portName ${narg}
            set _WD_port ${portName}
            incr i
        } else {
            set portName ""
        }
        if {!${missing} || ${portName} ne ""} {
            # we're pointed to a directory
            set pWD ${arg}
            cd ${pWD}
            set OK 1
            if {${portName} ne ""} {
                ui_msg "Checking in directory ${pWD}, comparing to port:${portName}"
            } else {
                ui_msg "Checking in directory ${pWD}"
            }
        } else {
            ui_error "\"Missing\" mode needs a portname, not a destroot directory!"
            exit 2
        }
    } elseif {${_WD_port} ne ${arg}} {
        set portName ${arg}
        set _WD_port ${portName}
        set pWD [port_workdir ${portName}]
        ui_msg "Checking port:${portName}: ${pWD}"
        if {[file exists "${pWD}/destroot"]} {
            cd "${pWD}/destroot"
            set OK 1
        }
    }
    if {${pWD} ne ""} {
        if {${OK}} {
            set FILES {}
            ui_debug "Building file list for ${portName}"
            Trawler foreach file {
                if {${missing}} {
                    set FILES [lappend FILES [string map [list "./" "/"] "${file}"]]
                } else {
                    set FILES [lappend FILES "${file}"]
                }
            }
            if {${missing}} {
                set currentFiles [port_contents ${portName}]
                ui_debug "Checking for files from\n\t\{${currentFiles}\}\nmissing from\n\t\{${FILES}\}"
                foreach f ${currentFiles} {
                    if {[lsearch -exact ${FILES} ${f}] < 0} {
                        message ${f} "will go missing"
                    }
                }
            } else {
                set InstalledDupsList {}
                set DestrootDupsList {}
                if {${newer}} {
                    ui_debug "Checking [llength ${FILES}] files for newer and new items"
                } elseif {${inverse}} {
                    ui_debug "Checking [llength ${FILES}] files for new, not-yet-installed items"
                } else {
                    ui_debug "Checking [llength ${FILES}] files for already installed copies"
                }
                foreach f $FILES {
                    set g [string range ${f} 1 end]
                    if {[file exists "${g}"]} {
                        if {[file type "${f}"] eq "file" && [file type "${g}"] eq "file"} {
                            if {${newer}} {
                                if {[file mtime ${f}] > [file mtime ${g}]} {
                                    if {[fileEqual ${f} ${g}]} {
                                        # check if the installed file is probably a headerfile
                                        if {$touchHeaders && [string first "/include/" ${g}]} {
                                            file mtime ${f} [file mtime ${g}]
                                            message ${g} "mtime set to that of the installed file"
                                        } else {
                                            message ${g} "will be touched"
                                        }
                                    } else {
                                        message ${g} "will be updated"
                                        if {${listnewer}} {
                                            message "" [exec ls -alsF ${f} ${g}]
                                        }
                                    }
                                }
                            } elseif {!${inverse}} {
                                set InstalledDupsList [lappend InstalledDupsList "${g}"]
                                set DestrootDupsList [lappend DestrootDupsList "${f}"]
                            }
                        }
                    } elseif {${inverse}} {
                        message ${g} "doesn't exist yet"
                    }
                }
                if {[llength ${InstalledDupsList}]} {
                    if {![macports::ui_isset ports_quiet]} {
                        ui_msg "[llength ${InstalledDupsList}] files already exist, checking if any do not already belong to another port than ${portName}"
                    }
                    set ProviderDict [port_provides ${InstalledDupsList}]
                    set DUPS {}
                    dict for {g provider} ${ProviderDict} {
                        if {${provider} ne ${portName}} {
                            regsub -all {[ \r\t\n]+} ${g} "" gg
                            if {${g} ne ${gg}} {
                                puts -nonewline "\"${g}\""
                            } else {
                                puts -nonewline "${g}"
                            }
                            if {![macports::ui_isset ports_quiet]} {
                                puts " already exists"
                                puts "\tprovided by: ${provider}"
                                system "ls -l \"./${g}\" \"${g}\""
                            } else {
                                puts "\t : ${provider}"
                            }
                            set DUPS [lappend DUPS [string cat "${g}" "\n"]]
                        }
                    }
                    if {[llength ${DUPS}]} {
                        puts [join ${DUPS}]
                    }
                    if {${checkdpkg} ne ""} {
                        if {${os.platform} eq "linux" || ${portName} eq "MacPorts-devel"} {
                            puts "check host packages with `dpkg -S ${checkdpkg}`"
                        }
                    }
                }
            }
        }
    }
}
