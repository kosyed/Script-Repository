#!/usr/bin/env bash

# https://github.com/kosyed/script-repository/firefox-on-linux
# Script installs offical stand-alone version of Firefox on linux, works well in Debian
# Resource: https://www.mozilla.org/firefox/all/

# Required:
PRODUCT="firefox-latest-ssl"                     # "firefox-esr-latest-ssl" for ESR
OS="linux64"                                     # "linux" for 32bit
LANG="en-GB"                                     # "en-US" for American English

# Additional:
REDOWNLOAD="no"                                  # "yes" to download firefox even when installer exists

######## SCRIPT ########
if [ -z "$PRODUCT" ] || [ -z "$OS" ] || [ -z "$LANG" ]; then
	echo "Required: PRODUCT, OS and LANG"
	exit 1
fi

if [[ $EUID -eq 0 ]]; then
	echo "Installing Firefox"
	else
	echo "Please run as root"
	exit 1	
fi

if [ -d "/opt/firefox" ]; then
	echo "Firefox folder already exists, exiting"
	exit 1
	else
	mkdir /opt
	cd /opt
fi

if [ ! -f firefox.tar.bz2 ] || [ "$REDOWNLOAD" == "yes" ]; then
	echo "Downloading Firefox"
	curl -sSL -o firefox.tar.bz2 "https://download.mozilla.org/?product=$PRODUCT&os=$OS&lang=$LANG"
	else
	DATE="$(stat -c '%y' firefox.tar.bz2  | grep -oP '^\S*' )"
	echo "Firefox already downloaded on $DATE"
fi

tar xjf firefox.tar.bz2 -C /opt/
ln -s /opt/firefox /usr/bin/firefox
echo "Firefox installed"
exit 0
