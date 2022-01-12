#!/bin/sh

ZFS_LOADED="`kextstat -k -l -b net.lundman.zfs`"

if [ "${ZFS_LOADED}" != "" ] ;then
	echo "ZFS kernel extension is loaded"
else
	echo "ZFS kernel extension is NOT loaded"
	exit 1
fi
