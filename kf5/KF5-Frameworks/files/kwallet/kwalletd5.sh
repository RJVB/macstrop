#!/bin/sh

KDE_SESSION_VERSION=5 ; export KDE_SESSION_VERSION

exec @LIBEXECDIR@/kwalletd5.app/Contents/MacOS/kwalletd5 "$@"
