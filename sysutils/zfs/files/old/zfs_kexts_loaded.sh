#!/bin/sh

SPL_LOADED="`kextstat -k -l -b net.lundman.spl`"
ZFS_LOADED="`kextstat -k -l -b net.lundman.zfs`"

if [ "${ZFS_LOADED}" != "" ] ;then
	echo "ZFS kernel extension is loaded"
else
	echo "ZFS kernel extension is NOT loaded"
	exit 1
fi
if [ "${SPL_LOADED}" != "" ] ;then
	echo "SPL kernel extension is loaded"
else
	echo "SPL kernel extension is NOT loaded"
	exit 1
fi
