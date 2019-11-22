#!/opt/local/libexec/macports/bin/tclsh8.5
# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:filetype=tcl:et:sw=4:ts=4:sts=4
# $Id:$

# Create a namespace for some local variables
namespace eval portclient::progress {
    ##
    # Indicate whether the term::ansi::send tcllib package is available and was
    # imported. "yes", if the package is available, "no" otherwise.
    variable hasTermAnsiSend no
}

if {![catch {package require term::ansi::send}]} {
    set portclient::progress::hasTermAnsiSend yes
}


package require Tclx
package require macports 1.0
package require Pextlib 1.0

array set ui_options        {}
array set global_options    {}
array set global_variations {}

# reinplace
# Provides "sed in place" functionality
set args $argv

# proc reinplace {args}  {
    global env workpath macosx_version ui_options
    set extended 0
    set suppress 0
    set quiet 0
    set oldlocale_exists 0
    set oldlocale ""
    set locale ""
    set dir ""
    while 1 {
        set arg [lindex $args 0]
        if {[string index $arg 0] eq "-"} {
            set args [lrange $args 1 end]
            switch -- [string range $arg 1 end] {
                locale {
                    set oldlocale_exists [info exists env(LC_CTYPE)]
                    if {$oldlocale_exists} {
                        set oldlocale $env(LC_CTYPE)
                    }
                    set locale [lindex $args 0]
                    set args [lrange $args 1 end]
                }
                E {
                    set extended 1
                }
                n {
                    set suppress 1
                }
                q {
                    set quiet 1
                }
                v {
                    puts "$args"
                    set ui_options(ports_verbose) yes
                }
                W {
                    set dir [lindex $args 0]
                    set args [lrange $args 1 end]
                }
                - {
                    break
                }
                default {
                    error "reinplace: unknown flag '$arg'"
                }
            }
        } else {
            break
        }
    }
    if {[llength $args] < 2} {
        error "reinplace ?-E? ?-n? ?-q? ?-W dir? pattern file ..."
    }
    set pattern [lindex $args 0]
    set files [lrange $args 1 end]

    ### init
    mportinit ui_options global_options global_variations
    #set os_platform [string tolower $tcl_platform(os)]
    set os_platform ${macports::os_platform}
    set os_subplatform {}
    set macosx_version ${macports::macosx_version}
    set os_version ${macports::os_version}
    set os_arch ${macports::os_arch}
    set portpath "./"
    set portbuildpath "./"
    set prefix_frozen ${macports::prefix}
    package require port 1.0
    ### init done

#     if {[file isdirectory ${workpath}/.tmp]} {
#         set tempdir ${workpath}/.tmp
#     } else {
        set tempdir /tmp
#     }

    foreach file $files {
        global UI_PREFIX

        # if $file is an absolute path already, file join will just return the
        # absolute path, otherwise it is $dir/$file
        set file [file join $dir $file]

        if {[catch {set tmpfile [mkstemp "${tempdir}/[file tail $file].sed.XXXXXXXX"]} error]} {
            ui_debug $::errorInfo
            ui_error "reinplace: $error"
            return -code error "reinplace failed"
        } else {
            # Extract the Tcl Channel number
            set tmpfd [lindex $tmpfile 0]
            # Set tmpfile to only the file name
            set tmpfile [join [lrange $tmpfile 1 end]]
        }

        set cmdline {}
        lappend cmdline $portutil::autoconf::sed_command
        if {$extended} {
            lappend cmdline -E
        }
        if {$suppress} {
            lappend cmdline -n
        }
        lappend cmdline $pattern "<$file" ">@$tmpfd"
        if {$locale ne ""} {
            set env(LC_CTYPE) $locale
        }
        ui_info "$UI_PREFIX [format [msgcat::mc "Patching %s: %s"] [file tail $file] $pattern]"
        ui_debug "Executing reinplace: $cmdline"
        if {[catch {exec -ignorestderr -- {*}$cmdline} error]} {
            ui_debug $::errorInfo
            ui_error "reinplace: $error"
            file delete "$tmpfile"
            if {$locale ne ""} {
                if {$oldlocale_exists} {
                    set env(LC_CTYPE) $oldlocale
                } else {
                    unset env(LC_CTYPE)
                }
            }
            close $tmpfd
            return -code error "reinplace sed(1) failed"
        }

        if {$locale ne ""} {
            if {$oldlocale_exists} {
                set env(LC_CTYPE) $oldlocale
            } else {
                unset env(LC_CTYPE)
            }
        }
        close $tmpfd

        if {!$quiet && ![catch {exec -ignorestderr cmp -s $file $tmpfile}]} {
            ui_warn "[format [msgcat::mc "reinplace %1\$s didn't change anything in %2\$s"] $pattern $file]"
        }

        set attributes [file attributes $file]
        chownAsRoot $file

        # We need to overwrite this file
        if {[catch {file attributes $file -permissions u+w} error]} {
            ui_debug $::errorInfo
            ui_error "reinplace: $error"
            file delete "$tmpfile"
            return -code error "reinplace permissions failed"
        }

        if {[catch {file copy -force $tmpfile $file} error]} {
            ui_debug $::errorInfo
            ui_error "reinplace: $error"
            file delete "$tmpfile"
            return -code error "reinplace copy failed"
        }

        fileAttrsAsRoot $file $attributes

        file delete "$tmpfile"
    }
    return
# }

#reinplace [lindex $argv 0] [lindex $argv 1]
#reinplace $argv
