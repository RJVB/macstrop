# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4

## PortGroup for ports that "just need" Python as a build or runtime dependency

set py_ver              3.12
set py_ver_nodot        [string map {. {}} ${py_ver}]

# find the oldest (= fastest) new-enough python version the user already has installed and return its path.
# if none are installed already, return 0 and set the py_ver variables to the latest specified version.
proc find_new_enough_python3 {{min_minor 2} {max_minor -1}} {
    global py_ver py_ver_nodot prefix
    if {${max_minor} < 0} {
        set max_minor [lindex [split ${py_ver} '.'] 1]
    }
    ui_debug "Looking for python3.${min_minor} to python3.${max_minor}"
    set found 0
    for {set pv ${min_minor}} {$pv < ${max_minor}} {incr pv 1} {
        if {[file exists ${prefix}/bin/python3.${pv}]} {
            set found 1
            break
        }
    }
    # set py_ver* even if we didn't find anyone, so the port can
    # simply use them to pull in the indicated latest version.
    set py_ver          "3.${pv}"
    set py_ver_nodot    [string map {. {}} ${py_ver}]
    if {${found}} {
        # if we did find an interpreter, return its path
        set found       ${prefix}/bin/python${py_ver}
    }
    return ${found}
}

# idem, but prefer python 2.7
proc find_new_enough_python2or3 {{min_minor3 2} {max_minor3 -1}} {
    global py_ver py_ver_nodot prefix
    if {${max_minor3} < 0} {
        set max_minor3 [lindex [split ${py_ver} '.'] 1]
    }
    ui_debug "Looking for python2.7 or python3.${min_minor3} to python3.${max_minor3}"
    if {[file exists ${prefix}/bin/python2.7]} {
        set py_ver          2.7
        set py_ver_nodot    27
        set found ${prefix}/bin/python2.7
    } else {
        set found 0
        for {set pv ${min_minor3}} {$pv < ${max_minor3}} {incr pv 1} {
            if {[file exists ${prefix}/bin/python3.${pv}]} {
                set found 1
                break
            }
        }
        set py_ver          "3.${pv}"
        set py_ver_nodot    [string map {. {}} ${py_ver}]
        if {${found}} {
            set found       ${prefix}/bin/python${py_ver}
        }
    }
    return ${found}
}

# find the newest Python version currently installed
proc find_latest_python3 {{min_minor 2} {max_minor -1}} {
    global py_ver py_ver_nodot prefix
    if {${max_minor} < 0} {
        set max_minor [lindex [split ${py_ver} '.'] 1]
    }
    ui_debug "Looking for python3.${min_minor} to python3.${max_minor}"
    set found 0
    for {set pv ${max_minor}} {$pv >= ${min_minor}} {incr pv -1} {
        if {[file exists ${prefix}/bin/python3.${pv}]} {
            set found 1
            break
        }
    }
    set py_ver          "3.${pv}"
    set py_ver_nodot    [string map {. {}} ${py_ver}]
    if {${found}} {
        set found       ${prefix}/bin/python${py_ver}
    }
    return ${found}
}

# idem, but prefer python 2.7
proc find_latest_python2or3 {{min_minor3 2} {max_minor3 -1}} {
    global py_ver py_ver_nodot prefix
    if {${max_minor3} < 0} {
        set max_minor3 [lindex [split ${py_ver} '.'] 1]
    }
    ui_debug "Looking for python2.7 or python3.${min_minor3} to python3.${max_minor3}"
    if {[file exists ${prefix}/bin/python2.7]} {
        set py_ver          2.7
        set py_ver_nodot    27
        set found ${prefix}/bin/python2.7
    } else {
        set found 0
        for {set pv ${max_minor}} {$pv >= ${min_minor}} {incr pv -1} {
            if {[file exists ${prefix}/bin/python3.${pv}]} {
                set found 1
                break
            }
        }
        set py_ver          "3.${pv}"
        set py_ver_nodot    [string map {. {}} ${py_ver}]
        if {${found}} {
            set found       ${prefix}/bin/python${py_ver}
        }
    }
    return ${found}
}
