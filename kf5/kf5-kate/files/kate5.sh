#!/bin/sh

export KDE_SESSION_VERSION=5
exec @KDEAPPDIR@/kate.app/Contents/MacOS/kate "$@"
