port:openwv installed the OpenWV plugin under @PREFIX@/libexec/openwv :

- the plugin binary is the libwidevinecdm.@EXT@ file in the root
- manifest.json files for both Firefox and Chromium based browsers
  are installed in subdirectories with the respective names.

Read the README.md file for detailed instructions on how to install
these files manually in each of those two browser families. Remember
that you need to restart the browser after doing a manual install!

Additionally, an installer script was installed for Firefox users:

@PREFIX@/libexec/openwv/bin/install_openwv4firefox <profiledirname>

will attempt to perform the installation for you (the browser MUST
NOT running when you do this!). Here, <profiledirname> is the full
of a profile directory.
These are stored  under ~/Library/Application Support/Firefox/Profiles
on Mac, or ~/.mozilla/firefox on Linux. You can find the correct
folder for the browser profile you want to use OpenWV with via
either the about:profiles page, or as "Profile Folder" on the
about:support page.
