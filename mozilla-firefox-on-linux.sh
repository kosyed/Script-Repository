#!/usr/bin/env bash

# https://github.com/kosyed/script-repository#mozilla-firefox-on-linux
# Script installs offical stand-alone version of Mozilla Firefox on linux, works well on Debian based distros
# Reference: https://wiki.debian.org/Firefox
# Reference for downloading: https://www.mozilla.org/firefox/all/

# Required:
PRODUCT="firefox-latest-ssl"                     # "firefox-esr-latest-ssl" for ESR
OS="linux64"                                     # "linux" for 32bit
LANG="en-GB"                                     # "en-US" for American English

# Additional:
REINSTALL=""                                     # "yes" to force reinstall
REDOWNLOAD=""                                    # "yes" to force download if installer exists

######## SCRIPT ########
if [ -z "$PRODUCT" ] || [ -z "$OS" ] || [ -z "$LANG" ]; then
	echo "Required: PRODUCT, OS and LANG"
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
	if [ -f "/usr/bin/mozilla-firefox" ]; then
		echo "Mozilla Firefox appears to be already installed"
		exit 0
	fi
fi

mkdir -p /tmp/mozilla-firefox-install
cd /tmp/mozilla-firefox-install

if [ ! -f firefox.tar.bz2 ] || [ "$REDOWNLOAD" == "yes" ]; then
	echo "Downloading Mozilla Firefox"
	curl -sSL -o firefox.tar.bz2 "https://download.mozilla.org/?product=$PRODUCT&os=$OS&lang=$LANG"
	SIZE="$(stat -c '%s' firefox.tar.bz2 2>/dev/null)"
	if [ ! -f firefox.tar.bz2 ] || [ "$SIZE" -lt "1024000" ]; then
		echo "Download Error"
		exit 1
	fi
	else
	DATE="$(stat -c '%y' firefox.tar.bz2  | grep -oP '^\S*' )"
	echo "Found Mozilla Firefox installer from $DATE"
fi

echo "Installing Mozilla Firefox"
tar xjf firefox.tar.bz2
mkdir -p /opt/mozilla-firefox
mv -v ./firefox/* /opt/mozilla-firefox/
rmdir ./firefox
chgrp -R users /opt/mozilla-firefox/
chmod -R g+w /opt/mozilla-firefox/
if [ ! -f "/opt/mozilla-firefox/firefox" ]; then
	echo "Install Error"
	exit 1
fi

cd /usr/bin
echo "Linking Mozilla Firefox"
ln -s /opt/mozilla-firefox/firefox /usr/bin/mozilla-firefox

cd /usr/share/applications/
if [ ! -f mozilla-firefox.desktop ]; then
	echo "Creating Mozilla Firefox Shortcut"
	SHORTCUT="mozilla-firefox.desktop"
	touch $SHORTCUT
	echo "[Desktop Entry]" >> $SHORTCUT
	echo "Version=1.0" >> $SHORTCUT
	echo "Name=Mozilla Firefox" >> $SHORTCUT
	echo "Comment=Browse the World Wide Web" >> $SHORTCUT
	echo "GenericName=Web Browser" >> $SHORTCUT
	echo "Keywords=Internet;WWW;Browser;Web;Explorer" >> $SHORTCUT
	echo "Exec=/opt/mozilla-firefox/firefox %u" >> $SHORTCUT
	echo "Terminal=false" >> $SHORTCUT
	echo "X-MultipleArgs=false" >> $SHORTCUT
	echo "Type=Application" >> $SHORTCUT
	echo "Icon=/opt/mozilla-firefox/browser/chrome/icons/default/default128.png" >> $SHORTCUT
	echo "Categories=GNOME;GTK;Network;WebBrowser;" >> $SHORTCUT
	echo "MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/echo \"rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-echo \"scheme-handler/chrome;video/webm;application/x-xpinstall;" >> $SHORTCUT
	echo "StartupWMClass=Firefox" >> $SHORTCUT
	echo "StartupNotify=false" >> $SHORTCUT
fi

echo "Mozilla Firefox Installed"
exit 0
