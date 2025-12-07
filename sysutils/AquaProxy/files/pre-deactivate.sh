#!/bin/bash

sudo sed -i -e '/setenv HTTPS_PROXY \(https\{0,1\}:\/\/\)\{0,1\}localhost:3128/d' /etc/launchd.conf >/dev/null 2>&1
sudo sed -i -e '/setenv HTTPS_PROXY \(https\{0,1\}:\/\/\)\{0,1\}127.0.0.1:3128/d' /etc/launchd.conf >/dev/null 2>&1

for pid_uid in $(ps -axo pid,uid,args | grep -i "[l]oginwindow.app" | awk '{print $1 "," $2}'); do
	pid=$(echo $pid_uid | cut -d, -f1)
	uid=$(echo $pid_uid | cut -d, -f2)
	if (( $(echo "${OSTYPE:6} > 13" | bc -l) ))
	then
		#Running OS X 10.10 or above
		launchctl bootout gui/$uid @PREFIX@/Library/LaunchAgents/Wowfunhappy.AquaProxy.HTTP.plist
		launchctl bootout gui/$uid @PREFIX@/Library/LaunchAgents/Wowfunhappy.AquaProxy.IMAP.plist
		launchctl bootout gui/$uid @PREFIX@/Library/LaunchAgents/Wowfunhappy.AquaProxy.SyncProxiesWithShell.plist
		launchctl bootout gui/$uid @PREFIX@/Library/LaunchAgents/Wowfunhappy.AquaProxy.Restarter.plist
	else
		#Running OS X 10.9 or below
		launchctl bsexec "$pid" chroot -u "$uid" / launchctl unload @PREFIX@/Library/LaunchAgents/Wowfunhappy.AquaProxy.HTTP.plist
		launchctl bsexec "$pid" chroot -u "$uid" / launchctl unload @PREFIX@/Library/LaunchAgents/Wowfunhappy.AquaProxy.IMAP.plist
		launchctl bsexec "$pid" chroot -u "$uid" / launchctl unload @PREFIX@/Library/LaunchAgents/Wowfunhappy.AquaProxy.SyncProxiesWithShell.plist
		launchctl bsexec "$pid" chroot -u "$uid" / launchctl unload @PREFIX@/Library/LaunchAgents/Wowfunhappy.AquaProxy.Restarter.plist
	fi
done

# Clean up any old "Aqua Proxy" certificates from previous installations.
sudo security delete-certificate -c "Aqua Proxy" /Library/Keychains/System.keychain >/dev/null 2>&1

security -v remove-trusted-cert -d @PREFIX@/Library/AquaProxy/AquaProxy-cert.pem

