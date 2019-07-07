#!/bin/sh

env KDE_SESSION_VERSION=5
@KDEAPPDIR@/kcmshell5.app/Contents/MacOS/kcmshell5 "$@" &
PID=$!

wait ${PID}
exit $?

# # cache current KDE_SESSION_VERSION setting
# KSV="`launchctl getenv KDE_SESSION_VERSION`"
# if [ "${KDE_SESSION_VERSION}" != "" ] ;then
#     launchctl setenv KDE_SESSION_VERSION "${KDE_SESSION_VERSION}"
# else
#     # KDE_SESSION_VERSION not set; unset it for LaunchServices too.
#     # Note that this doesn't appear to be effective for the kcmshell5.app
#     # instance we'll be launching.
#     launchctl unsetenv KDE_SESSION_VERSION
# fi
# 
# open -W -n -a @KDEAPPDIR@/kcmshell5.app --args "$@" &
# PID=$!
# 
# # restore what we changed
# if [ "${KSV}" != "" ] ;then
#     launchctl setenv KDE_SESSION_VERSION "${KSV}"
# else
#     launchctl unsetenv KDE_SESSION_VERSION
# fi
# 
# # wait for kcmshell5 to exit and raise its return code
# wait ${PID}
# exit $?
