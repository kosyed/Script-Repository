#!/usr/bin/env bash

# https://github.com/kosyed/script-repository#google-chrome-on-linux
# Script installs Google Chrome on Debian based distros
# Reference: https://www.google.com/chrome/
# Reference for repo: https://www.google.com/linuxrepositories/

# Required:
VERSION="stable"                                 # "beta" for Beta version, "unstable" for Developer version

# Additional:
GOOGLE_REPO=""                                   # "no" to prevent chrome from adding Google's update repository
REINSTALL=""                                     # "yes" to force reinstall
REDOWNLOAD=""                                    # "yes" to force download if installer exists

######## SCRIPT ########
if [ "$VERSION" == "stable" ] || [ "$VERSION" == "beta" ] || [ "$VERSION" == "unstable" ]; then
	:
	else
	echo "Required: VERSION"
	exit 1
fi

if [[ $EUID -eq 0 ]]; then
	if [ ! -f /usr/bin/curl ]; then
		echo "Curl is required, trying to install"
		apt-get install curl
	fi
	else
	echo "Please run as root"
	exit 1	
fi

if [ "$REINSTALL" == "yes" ]; then
	:
	else
	if [ -f "/usr/bin/google-chrome" ]; then
		echo "Google Chrome appears to be already installed"
		exit 0
	fi
fi

mkdir -p /tmp/google-chrome-install
cd /tmp/google-chrome-install

if [ ! -f chrome.deb ] || [ "$REDOWNLOAD" == "yes" ]; then
	echo "Downloading Google Chrome"
	curl -sSL -o chrome.deb "https://dl.google.com/linux/direct/google-chrome-"$VERSION"_current_amd64.deb"
	SIZE="$(stat -c '%s' chrome.deb)"
	if [ ! -f chrome.deb ] || [ "$SIZE" -lt "1024000" ]; then
		echo "Download Error"
		exit 1
	fi
	else
	DATE="$(stat -c '%y' chrome.deb  | grep -oP '^\S*' )"
	echo "Found Google Chrome installer from $DATE"
fi

echo "Installing Google Chrome"
if [ "$GOOGLE_REPO" == "no" ] && [ ! -f "/etc/default/google-chrome" ]; then
	touch /etc/default/google-chrome
fi
dpkg -i chrome.deb >/dev/null
if [ ! -f "/usr/bin/google-chrome" ]; then
	echo "Install Error"
	exit 1
fi

echo "Google Chrome Installed"
exit 0
