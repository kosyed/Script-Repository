#!/usr/bin/env bash

# https://github.com/kosyed/script-repository#post-install-preferences
# Script for a range of preferences, maybe run as "sudo post-install-preferences.sh && post-install-preferences.sh"

# Reference for Grub: https://www.gnu.org/software/grub/manual/grub/grub.html#Simple-configuration
RUN_GRUB="no"                                    # "yes" to run
GRUB_DEFAULT=0
GRUB_TIMEOUT=1

# Reference for Firefox: http://kb.mozillazine.org/User.js_file
RUN_FIREFOX="no"                                 # "yes" to run
FIREFOX_DIR=""                                   # ~/.mozilla/firefox/[FIREFOX_DIR]/
FIREFOX_PREF="
user_pref(\"browser.backspace_action\", 0);
user_pref(\"browser.urlbar.doubleClickSelectsAll\", false);
user_pref(\"security.certerrors.permanentOverride\", false);
"

######## SCRIPT ########

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
	if [ -z "$FIREFOX_DIR" ]; then
		echo "Firefox requires: FIREFOX_DIR"
		else
		if [[ $EUID -eq 0 ]]; then
			echo "Firefox update requires no root"
			else
			echo "Running Firefox, preferences will take effect on next start"
			echo "$FIREFOX_PREF" > ~/.mozilla/firefox/$FIREFOX_DIR/user.js
		fi
	fi
fi

echo "Done"
exit 0
