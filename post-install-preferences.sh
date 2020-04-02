#!/usr/bin/env bash

# https://github.com/kosyed/script-repository#post-install-preferences
# Script for a range of preferences, maybe run as "sudo post-install-preferences.sh && post-install-preferences.sh"

# Reference for Apt-Get: https://wiki.debian.org/Software
RUN_APTGET="no"                                  # "yes" to run
APTGET_PREF=(
filezilla
ghex
gimp
#hugo
inkscape
luckybackup
meld
numlockx
sqlitebrowser
transmission
#virt-manager
whois
)

# Reference for Grub: https://www.gnu.org/software/grub/manual/grub/grub.html#Simple-configuration
RUN_GRUB="no"                                    # "yes" to run
GRUB_DEFAULT=0
GRUB_TIMEOUT=1

# Reference for Firefox: http://kb.mozillazine.org/User.js_file
RUN_FIREFOX="no"                                 # "yes" to run
FIREFOX_DIR=""                                   # ~/.mozilla/firefox/[FIREFOX_DIR]/
FIREFOX_PREF='
user_pref("browser.backspace_action", 0);
user_pref("browser.urlbar.doubleClickSelectsAll", false);
user_pref("security.certerrors.permanentOverride", false);
'

######## SCRIPT ########

# Apt-Get
if [ "$RUN_APTGET" == "yes" ]; then
	if [[ $EUID -eq 0 ]]; then
		echo "Running Apt-Get"
		apt-get update
		for i in "${APTGET_PREF[@]}"; do
			apt-get install $i -qq >/dev/null
		done
		else
		echo "Apt-Get update requires root"
	fi
fi

# Grub
if [ "$RUN_GRUB" == "yes" ]; then
	if [[ $EUID -eq 0 ]]; then
		echo "Running Grub"
		sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=$GRUB_DEFAULT/" /etc/default/grub
		sed -i "s/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=$GRUB_TIMEOUT/" /etc/default/grub
		update-grub 2>/dev/null
		else
		echo "Grub update requires root"
	fi
fi

# Firefox
if [ "$RUN_FIREFOX" == "yes" ]; then
	if [[ $EUID -eq 0 ]]; then
		echo "Firefox update requires not being root"
		else
		if [ -z "$FIREFOX_DIR" ]; then
			echo "FIREFOX_DIR not specified, finding an existing user.js"
			FIREFOX_DIR="$(find ~/.mozilla/firefox -maxdepth 2 -name user.js | grep -oP '(?<=.mozilla/firefox/)[^/]*' )"
			if [ -z "$FIREFOX_DIR" ]; then
				echo "Could not find file, finding a profile to create one"
				FIREFOX_DIR="$(find ~/.mozilla/firefox -maxdepth 2 -name prefs.js | grep -oP '(?<=.mozilla/firefox/)[^/]*' )"
			fi
			FIREFOX_DIRCHECK="$(echo "$FIREFOX_DIR" | wc -l )"
			if [ ! -z "$FIREFOX_DIR" ] && [ "$FIREFOX_DIRCHECK" = "1" ]; then
				echo "Updating user.js, changes will take effect on next start. Save in script to optimise - $FIREFOX_DIR"
				echo "$FIREFOX_PREF" > ~/.mozilla/firefox/$FIREFOX_DIR/user.js
				else
				echo "Error finding directory. If any were found they will be listed below, please define one in script"
				echo "$FIREFOX_DIR"
			fi
			else
			echo "Updating user.js, changes will take effect on next start"
			echo "$FIREFOX_PREF" > ~/.mozilla/firefox/$FIREFOX_DIR/user.js
		fi
	fi
fi

echo "Done"
exit 0
