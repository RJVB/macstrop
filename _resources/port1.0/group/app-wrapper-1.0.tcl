# create a wrapper script in ${prefix}/bin for an application bundle in qt_apps_dir
options appwrap.wrapper_env_additions
default appwrap.wrapper_env_additions ""

proc appwrap.add_app_wrapper {wrappername {bundlename ""} {bundleexec ""} {appdir ""}} {
    global applications_dir destroot prefix os.platform appwrap.wrapper_env_additions subport
    if {${os.platform} eq "darwin"} {
        if {${appdir} eq ""} {
            set appdir ${applications_dir}
        }
        if {${bundlename} eq ""} {
            set bundlename ${wrappername}
        }
        if {${bundleexec} eq ""} {
            set bundleexec [file tail ${bundlename}]
        }
    } else {
        # no app bundles on this platform, but provide the same API by pretending there are.
        # If unset, use ${subport} to guess the exec. name because evidently we cannot
        # symlink ${wrappername} onto itself.
        if {${appdir} eq ""} {
            set appdir ${prefix}/bin
        }
        if {${bundlename} eq ""} {
            set bundlename ${subport}
        }
        if {${bundleexec} eq ""} {
            set bundleexec ${bundlename}
        }
    }
    if {${bundleexec} eq "${prefix}/bin/${wrappername}"
            || "${appdir}/${bundleexec}" eq "${prefix}/bin/${wrappername}"} {
        ui_error "appwrap.add_app_wrapper: wrapper ${wrappername} would overwrite executable ${bundleexec}: ignoring!"
        return;
    }
    xinstall -m 755 -d ${destroot}${prefix}/bin
    if {![catch {set fd [open "${destroot}${prefix}/bin/${wrappername}" "w"]} err]} {
        # this wrapper exists to a large extent to improve integration of the target
        # app with KF5 apps. Hence the reference to KDE things in the preamble.
        puts ${fd} "#!/bin/sh\n\
            if \[ -r ~/.kf5.env \] ;then\n\
            \t. ~/.kf5.env\n\
            else\n\
            \texport KDE_SESSION_VERSION=5\n\
            fi"
        set wrapper_env_additions "[join ${appwrap.wrapper_env_additions}]"
        if {${wrapper_env_additions} ne ""} {
            puts ${fd} "# Additional env. variables specified by port:${subport} :"
            puts ${fd} "export ${wrapper_env_additions}"
            puts ${fd} "#"
        }
        if {${os.platform} eq "darwin"} {
            if {[file dirname ${bundleexec}] eq "."} {
                puts ${fd} "exec \"${appdir}/${bundlename}.app/Contents/MacOS/${bundleexec}\" \"\$\@\""
            } else {
                # fully qualified bundleexec, use "as is"
                puts ${fd} "exec \"${bundleexec}\" \"\$\@\""
            }
        } else {
            puts ${fd} "if \[ \"\$\{LD_LIBRARY_PATH\}\" = \"\" \] \;then"
            puts ${fd} "    export LD_LIBRARY_PATH=${prefix}/lib"
            puts ${fd} "else"
            puts ${fd} "    export LD_LIBRARY_PATH=\$\{LD_LIBRARY_PATH\}:${prefix}/lib"
            puts ${fd} "fi"
            if {[file dirname ${bundleexec}] eq "."} {
                puts ${fd} "exec \"${appdir}/${bundleexec}\" \"\$\@\""
            } else {
                puts ${fd} "exec \"${bundleexec}\" \"\$\@\""
            }
        }
        close ${fd}
        system "chmod 755 ${destroot}${prefix}/bin/${wrappername}"
    } else {
        ui_error "Failed to (re)create \"${destroot}${prefix}/bin/${wrappername}\" : ${err}"
        return -code error ${err}
    }
}


