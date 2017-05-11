#!/bin/bash

# Debug Modus
DEBUG="OFF"

# Easy-WI Masterserver User
MASTERSERVER_USER="easy-wi"

# E-Mail Modul for Autoupdater
# deactivate E-Mail Support with empty EMAIL_TO Field
EMAIL_TO=""

# Mod ID´s for Modus "Install all ModIDs"
# Following Mods will be install:
# 525507438 - K9 Custom Stacks Size
# 479295136 - Aku Shima
# 632091170 - No Collision Structures
# 485964701 - Ark Reborn
# 558079412 - Admin Command Menu (ACM)
ARK_MOD_ID=("525507438" "479295136" "632091170" "485964701" "558079412")


##########################################
######## from here nothing change ########
##########################################

CURRENT_MANAGER_VERSION="2.5.7"
ARK_APP_ID="346110"
MASTER_PATH="/home/$MASTERSERVER_USER"
STEAM_CMD_PATH="$MASTER_PATH/masterserver/steamCMD/steamcmd.sh"
ARK_MOD_PATH="$MASTER_PATH/masteraddons"
EASYWI_XML_FILES="$MASTER_PATH/easywi-xml-files"
LOG_PATH="$MASTER_PATH/logs"
MOD_LOG="$LOG_PATH/ark_mod_id.log"
MOD_BACKUP_LOG="$LOG_PATH/ark_mod_id_backup.log"
MOD_NO_UPDATE_LOG="$LOG_PATH/ark_mod_id_no_update.log"
MOD_LAST_VERSION="$MASTER_PATH/versions"
TMP_PATH="$MASTER_PATH/temp"
CURRENT_UPDATER_VERSION="$(cat /root/ark_mod_updater.sh | grep CURRENT_UPDATER_VERSION= | grep -o -E '[0-9].[0-9]')"
DEAD_MOD="deprec|outdated|brocken|not-supported|mod-is-dead|no-longer-|old|discontinued"

PRE_CHECK() {
	clear
	HEADER
	if [ ! -f "$TMP_PATH"/ark_mod_updater_status ]; then
		if [ ! -d "$MOD_LAST_VERSION" ]; then
			su "$MASTERSERVER_USER" -c "mkdir -p "$MOD_LAST_VERSION""
		fi
		VERSION_CHECK
		UPDATER_CHECK
		USER_CHECK
		MENU
	else
		redMessage "Updater is currently running... please try again later."
		echo
		yellowMessage "Thanks for using this script and have a nice Day."
		HEADER
		tput cnorm; echo; exit
	fi
	sleep 2
}

VERSION_CHECK() {
	yellowMessage "Checking for the latest Manager Script"
	LATEST_MANAGER_VERSION=`wget -q --timeout=60 -O - https://api.github.com/repos/Lacrimosa99/Easy-WI-ARK-Mod-Manager/releases/latest | grep -Po '(?<="tag_name": ")([0-9]\.[0-9]\.[0-9])'`
	sleep 3

	if [ ! "$LATEST_MANAGER_VERSION" = "" ]; then
		if [ "`printf "${LATEST_MANAGER_VERSION}\n${CURRENT_MANAGER_VERSION}" | sort -V | tail -n 1`" != "$CURRENT_MANAGER_VERSION" ]; then
			redMessage "You are using a old Manager Script Version ${CURRENT_MANAGER_VERSION}."
			redMessage "Please upgrade to Version ${LATEST_MANAGER_VERSION} and retry."
			redMessage "Download Link: https://github.com/Lacrimosa99/Easy-WI-ARK-Mod-Manager/releases"
			FINISHED
		else
			greenMessage "You are using the Up-to-Date Manager Version ${CURRENT_MANAGER_VERSION}"
			sleep 5
			echo
		fi
	else
		redMessage "Could not detect on Github the last Manager Script Version!"
		FINISHED
	fi
}

USER_CHECK() {
	echo
	if [ ! "$MASTERSERVER_USER" = "" ]; then
		USER_CHECK=$(cut -d: -f6,7 /etc/passwd | grep "$MASTERSERVER_USER" | head -n1)
		if ([ ! "$USER_CHECK" == "/home/$MASTERSERVER_USER:/bin/bash" -a ! "$USER_CHECK" == "/home/$MASTERSERVER_USER/:/bin/bash" ]); then
			redMessage "User $MASTERSERVER_USER not found or wrong shell rights!"
			redMessage "Please check the Masteruser inside this Script or the User Shell rights."
			FINISHED
		fi
		if [ ! -d "$ARK_MOD_PATH" ]; then
			redMessage "Masteraddons Directory not found!"
			FINISHED
		fi
		if [ ! -f "$STEAM_CMD_PATH" ]; then
			redMessage "Steam installation not found!"
			FINISHED
		fi
	else
		redMessage 'Variable "MASTERSERVER_USER" are empty!'
		FINISHED
	fi
}

UPDATER_CHECK() {
	yellowMessage "Checking for the latest Updater Script"
	LATEST_UPDATER_VERSION=`wget -q --timeout=60 -O - https://api.github.com/repos/Lacrimosa99/Easy-WI-ARK-Mod-Updater/releases/latest | grep -Po '(?<="tag_name": ")([0-9]\.[0-9])'`
	sleep 3

	if [ ! "$LATEST_UPDATER_VERSION" = "" ]; then
		if [ "`printf "${LATEST_UPDATER_VERSION}\n${CURRENT_UPDATER_VERSION}" | sort -V | tail -n 1`" != "$CURRENT_UPDATER_VERSION" ]; then
			redMessage "A old Update Script is found and will Updated"
			rm -rf /root/ark_mod_updater.sh
			sleep 3
			echo
			yellowMessage "Downloading the last stable Updater Script from Github"
			yellowMessage "Please wait..."
			wget -q --timeout=60 -P /tmp/ https://github.com/Lacrimosa99/Easy-WI-ARK-Mod-Updater/archive/"$LATEST_UPDATER_VERSION".tar.gz
			tar zxf /tmp/"$LATEST_UPDATER_VERSION".tar.gz -C /tmp/
			rm -rf /tmp/"$LATEST_UPDATER_VERSION".tar.gz
			mv /tmp/Easy-WI-ARK-Mod-Updater-"$LATEST_UPDATER_VERSION"/ark_mod_updater.sh /root/
			rm -rf /tmp/Easy-WI-ARK-Mod-Updater-"$LATEST_UPDATER_VERSION"

			if [ -f /root/ark_mod_updater.sh ]; then
				chmod 700 /root/ark_mod_updater.sh >/dev/null 2>&1
				sed -i "s/unknown_user/$MASTERSERVER_USER/" /root/ark_mod_updater.sh

				if [ ! "$EMAIL_TO" = "" ]; then
					sed -i "s/EMAIL_TO=/EMAIL_TO=\"$EMAIL_TO\"/" /root/ark_mod_updater.sh
				fi
				sleep 3
				greenMessage "Done"
				sleep 5
				echo
			else
				redMessage "Updater Script downloading failed"
				redMessage "Please download the last release under https://github.com/Lacrimosa99/Easy-WI-ARK-Mod-Updater/releases"
				redMessage "Installation canceled!"
				FINISHED
			fi
		else
			greenMessage "You are using the Up-to-Date Updater Version ${CURRENT_UPDATER_VERSION}"
			sleep 5
			echo
		fi
	else
		echo
		redMessage "Could not detect last Updater Version!"
		FINISHED
	fi
}

MENU() {
	clear
	HEADER
	whiteMessage "1  -  Install a certain ModID"
	whiteMessage "2  -  Install all ModIDs"
	whiteMessage "3  -  Install Updater Script and Cronjob"
	echo
	whiteMessage "5  -  Update all installed ModIDs"
	echo
	whiteMessage "7  -  Uninstall a certain ModID"
	whiteMessage "8  -  Uninstall all ModIDs"
	whiteMessage "9  -  Uninstall Updater Script"
	echo
	whiteMessage "0  -  EXIT"
	echo
	echo
	printf "Number:  "; read -n1 number

	case $number in
		1)
			tput civis; MODE=INSTALL; INSTALL;;

		2)
			tput civis; MODE=INSTALLALL; INSTALL_ALL;;

		3)
			tput civis; UPDATER_INSTALL;;

		5)
			tput civis; MODE=UPDATE; UPDATE;;

		7)
			tput civis; UNINSTALL;;

		8)
			tput civis; UNINSTALL_ALL;;

		9)
			tput civis; UPDATER_UNINSTALL;;

		0)
			FINISHED;;

		*)
			ERROR; MENU;;
	esac
}

INSTALL() {
	echo; echo
	unset ARK_MOD_ID
	touch "$TMP_PATH"/ark_mod_updater_status
	tput cnorm
	printf "Please enter your ModID and press Enter: "; read ARK_MOD_ID
	tput civis

	if [ ! "$ARK_MOD_ID" = "" ]; then
		QUESTION4
		if [ ! -d "$ARK_MOD_PATH"/ark_"$ARK_MOD_ID" ]; then
			INSTALL_CHECK
			if [ -f "$MOD_BACKUP_LOG" ] && [ "$ARK_MOD_NAME_DEPRECATED" = "" ]; then
				rm -rf "$MOD_BACKUP_LOG"
			fi
			rm -rf "$TMP_PATH"/ark_mod_updater_status
			CLEANFILES
			QUESTION1
		else
			echo
			redMessage "Mod "$ARK_MOD_NAME_NORMAL" is already installed."
			redMessage "Installation canceled!"
			QUESTION1
		fi
	else
		rm -rf "$TMP_PATH"/ark_mod_updater_status
		ERROR
		INSTALL
	fi
}

INSTALL_ALL() {
	echo; echo; tput cnorm
	printf "Really install all ModIDs [Y/N]?: "; read -n1 ANSWER
	tput civis
	case $ANSWER in
		y|Y|j|J)
			echo;;
		n|N)
			FINISHED;;
		*)
			ERROR; INSTALL_ALL;;
	esac

	if [ ! -f "$MOD_LOG" ] && [ ! -f "$MOD_BACKUP_LOG" ]; then
		QUESTION7
		yellowMessage "Please wait..."
		INSTALL_CHECK
		echo; echo
		cyanMessage "List of installed Mods:"
		echo
		cat "$MOD_LOG" | sort
		FINISHED
	else
		redMessage "This Option is for first Mod installation only."
		redMessage "Installation canceled!"
		FINISHED
	fi
}

UPDATE() {
	echo; echo

	unset ARK_MOD_ID
	if [ ! -f "$TMP_PATH"/ark_mod_updater_status ]; then
		touch "$TMP_PATH"/ark_mod_updater_status
	else
		redMessage "Update in work... aborted!"
		echo
		FINISHED
	fi

	CLEANFILES
	if [ -f "$MOD_LOG" ]; then
		if [ -f "$MOD_BACKUP_LOG" ]; then
			rm -rf "$MOD_BACKUP_LOG"
		fi
		cp "$MOD_LOG" "$TMP_PATH"/ark_custom_appid_tmp.log
		mv "$MOD_LOG" "$MOD_BACKUP_LOG"
	elif [ -f "$MOD_BACKUP_LOG" ]; then
		cp "$MOD_BACKUP_LOG" "$TMP_PATH"/ark_custom_appid_tmp.log
	else
		echo
		redMessage 'File "ark_mod_id.log" in /logs not found!'
		redMessage "Update canceled!"
		rm -rf "$TMP_PATH"/ark_mod_updater_status
		FINISHED
	fi

	if [ -f "$TMP_PATH"/ark_custom_appid_tmp.log ]; then
		ARK_MOD_ID=$(cat "$TMP_PATH"/ark_custom_appid_tmp.log)
		INSTALL_CHECK
	fi
	if [ -f "$TMP_PATH"/ark_update_failure.log ]; then
		echo; echo
		yellowMessage "Wait 2 Minutes to redownload failed IDs."
		rm -rf $STEAM_CONTENT_PATH/*
		rm -rf $STEAM_DOWNLOAD_PATH/*
		sleep 120
		COUNTER=0
		unset ARK_MOD_ID
		ARK_MOD_ID=$(cat "$TMP_PATH"/ark_update_failure.log)
		INSTALL_CHECK
	fi
	if ! cmp -s "$MOD_LOG" "$MOD_BACKUP_LOG"; then
		echo; echo
		redMessage "Error in Logfile found!"
		redMessage "Logfile Backup restored"
		cp "$MOD_BACKUP_LOG" "$MOD_LOG"
	fi
	rm -rf "$TMP_PATH"/ark_mod_updater_status >/dev/null 2>&1
	FINISHED
}

UPDATER_INSTALL() {
	echo; echo

	yellowMessage "Check, is Cronjob already installed."
	if [ ! -f /etc/cron.d/ark_mod_updater ]; then
		echo '0 */2 * * * root /root/ark_mod_updater.sh >/dev/null 2>&1' > /etc/cron.d/ark_mod_updater

		if [ -f /etc/cron.d/ark_mod_updater ]; then
			systemctl daemon-reload >/dev/null 2>&1
			service cron restart >/dev/null 2>&1
			greenMessage "Updater Cron successfully installed."
			sleep 3
			echo
		else
			redMessage "Updater Cron installation failed!"
			FINISHED
		fi
	else
		greenMessage "Updater Cron already installed."
		sleep 3
		echo
	fi

	if [ -f /root/ark_mod_updater.sh ] && [ -f /etc/cron.d/ark_mod_updater ]; then
		screen -AmdS ARK_Updater "/root/ark_mod_updater.sh"
		greenMessage "Updater successfully installed and run for the first time in background."
	else
		redMessage "Updater installation failed!"
		redMessage "Cron and Updater will be removed!"
		sleep 3
		UPDATER_UNINSTALL
	fi
	FINISHED
}

UPDATER_UNINSTALL() {
	echo; echo; tput cnorm
	printf "Really uninstall Updater [Y/N]?: "; read -n1 ANSWER
	tput civis
	case $ANSWER in
		y|Y|j|J)
			echo;;
		n|N)
			FINISHED;;
		*)
			ERROR; UPDATER_UNINSTALL;;
	esac

	if [ -f /etc/cron.d/ark_mod_updater ]; then
		rm -rf /etc/cron.d/ark_mod_updater

		if [ ! -f /etc/cron.d/ark_mod_updater ]; then
			systemctl daemon-reload >/dev/null 2>&1 && service cron restart >/dev/null 2>&1
			greenMessage "Updater Cron successfully uninstalled."
		else
			redMessage "Updater Cron uninstalling failed!"
			redMessage 'Delete "ark_mod_updater" in "/etc/cron.d/" by Hand.'
			echo
		fi
	else
		redMessage 'No Updater Cron in "/etc/cron.d/" found!'
	fi

	if [ -f /root/ark_mod_updater.sh ]; then
		rm -rf /root/ark_mod_updater.sh

		if [ ! -f /root/ark_mod_updater.sh ]; then
			greenMessage "Updater successfully uninstalled."
			FINISHED
		else
			redMessage "Updater uninstalling failed!"
			redMessage 'Delete "ark_mod_updater.sh" in "/root/" by Hand.'
			FINISHED
		fi
	else
		redMessage 'No Updater in "/root/" found!'
		redMessage "Uninstalling canceled."
		FINISHED
	fi
}

UNINSTALL() {
	echo; echo; echo
	if [ -f "$MOD_LOG" ]; then
		unset ARK_MOD_ID
		yellowMessage "List of installed Mods:"
		echo
		ARK_MOD_LIST=$(cat "$MOD_LOG" && if [ -f "$MOD_NO_UPDATE_LOG" ]; then cat "$MOD_NO_UPDATE_LOG"; fi | sort)
		for MODID in ${ARK_MOD_LIST[@]}; do
			MOD_NAME_CHECK
			echo "$MODID - $ARK_MOD_NAME_NORMAL"
		done

		echo; echo;	tput cnorm
		printf "Please enter your ModID and press Enter: "; read ARK_MOD_ID
		tput civis

		if [ ! "$ARK_MOD_ID" = "" ]; then
			local UNINSTALL_TMP_NAME=$(cat "$MOD_LOG" | grep "$ARK_MOD_ID")
			local UNINSTALL_TMP_NAME2=$(if [ -f "$MOD_NO_UPDATE_LOG" ]; then cat "$MOD_NO_UPDATE_LOG" | grep "$ARK_MOD_ID"; fi)
			local UNINSTALL_TMP_PATH=$(ls "$ARK_MOD_PATH"/ | grep ark_"$ARK_MOD_ID")
			if [ ! "$UNINSTALL_TMP_NAME" = "" -a ! "$UNINSTALL_TMP_PATH" = "" ] || [ ! "$UNINSTALL_TMP_NAME2" = "" -a ! "$UNINSTALL_TMP_PATH" = "" ]; then
				QUESTION4
				rm -rf "$ARK_MOD_PATH"/ark_"$ARK_MOD_ID" >/dev/null 2>&1
				rm -rf "$EASYWI_XML_FILES"/"$ARK_MOD_NAME".xml >/dev/null 2>&1
				rm -rf "$MOD_LAST_VERSION"/ark_mod_id_"$ARK_MOD_ID".txt >/dev/null 2>&1
				sed -i "/$ARK_MOD_ID/d" "$MOD_LOG" >/dev/null 2>&1
				sed -i "/$ARK_MOD_ID/d" "$MOD_BACKUP_LOG" >/dev/null 2>&1
				sed -i "/$ARK_MOD_ID/d" "$MOD_NO_UPDATE_LOG" >/dev/null 2>&1
				DATABASE_STRING=$(echo "DELETE FROM addons WHERE addons.addon = 'ark_$ARK_MOD_ID'")
				DATABASE_CONNECTION
				sleep 3
				local UNINSTALL_TMP_NAME3=$(if [ -f "$MOD_NO_UPDATE_LOG" ]; then cat "$MOD_NO_UPDATE_LOG"; fi)
				if [ "$UNINSTALL_TMP_NAME3" = "" ]; then
					rm -rf "$MOD_NO_UPDATE_LOG" >/dev/null 2>&1
				fi
				echo
				greenMessage "ModID $ARK_MOD_ID is successfully uninstalled."
				echo
				local CHECK_LOG=$(cat "$MOD_LOG")
				if [ ! "$CHECK_LOG" = "" ]; then
					QUESTION3
				else
					redMessage 'No more installed Mod IDs in "ark_mod_id.log" found!'
					rm -rf "$MOD_LOG"
					echo
					QUESTION2
				fi
			else
				echo
				redMessage "Unknown ARK MOD ID!"
				redMessage "Uninstalling canceled."
				FINISHED
			fi
		else
			ERROR; UNINSTALL
		fi
	else
		redMessage 'File "ark_mod_id.log" in /logs not found!'
		redMessage "Uninstall canceled!"
		FINISHED
	fi
}

UNINSTALL_ALL() {
	echo; echo; tput cnorm
	printf "Really uninstall all Mod IDs [Y/N]?: "; read -n1 ANSWER
	tput civis
	case $ANSWER in
		y|Y|j|J)
			echo;;
		n|N)
			FINISHED;;
		*)
			ERROR; UNINSTALL_ALL;;
	esac

	if [ -f "$MOD_LOG" ]; then
		local DELETE_MOD=$(cat "$MOD_LOG" && if [ -f "$MOD_NO_UPDATE_LOG" ]; then cat "$MOD_NO_UPDATE_LOG"; fi | cut -c 1-9 )

		if [ ! "$DELETE_MOD" = "" ]; then
			for DELETE in ${DELETE_MOD[@]}; do
				rm -rf "$ARK_MOD_PATH"/ark_"$DELETE" >/dev/null 2>&1
				DATABASE_STRING=$(echo "DELETE FROM addons WHERE addons.addon = 'ark_"$DELETE"'")
				DATABASE_CONNECTION
			done
			rm -rf "$EASYWI_XML_FILES" >/dev/null 2>&1
			rm -rf "$MOD_LAST_VERSION"/ark_mod_id_"$ARK_MOD_ID".txt >/dev/null 2>&1
		fi

		if [ -f "$MOD_LOG" ] || [ -f "$MOD_BACKUP_LOG" ]; then
			rm -rf "$LOG_PATH"/ark_mod_* >/dev/null 2>&1
		fi

		greenMessage "all Mods successfully uninstalled."
		FINISHED
	else
		echo; echo
		redMessage "File $LOG_PATH/ark_mod_id.log not found!"
		redMessage "Delete all exist ARK Mod Folder by Hand."
		FINISHED
	fi

}

MOD_NAME_CHECK() {
	ARK_MOD_NAME_NORMAL=$(curl -s "http://steamcommunity.com/sharedfiles/filedetails/?id=$MODID" | sed -n 's|^.*<div class="workshopItemTitle">\([^<]*\)</div>.*|\1|p' | tr -d "\t,';=")
	ARK_LAST_CHANGES_DATE=$(curl -s "https://steamcommunity.com/sharedfiles/filedetails/changelog/$MODID" | sed -n 's|^.*Update: \([^<]*\)</div>.*|\1|p' | head -n1 | tr -d ',\t')
	ARK_MOD_NAME_TMP=$(echo "$ARK_MOD_NAME_NORMAL" | egrep "Difficulty|ItemTweaks|NPC")
	if [ ! "$ARK_MOD_NAME_TMP" = "" ]; then
		ARK_MOD_NAME=$(echo "$ARK_MOD_NAME_NORMAL" | tr "/" "-" | tr "[A-Z]" "[a-z]" | tr " " "-" | tr -d ".,!()[]" | sed "s/-updated//;s/+/-plus/;s/+/plus/" | sed 's/\\/-/;s/\\/-/;s/---/-/')
	else
		ARK_MOD_NAME=$(echo "$ARK_MOD_NAME_NORMAL" | tr "/" "-" | tr "[A-Z]" "[a-z]" | tr " " "-" | tr -d ".,+!()[]" | sed "s/-updated//;s/-v[0-9][0-9]*//;s/-[0-9][0-9]*//" | sed 's/\\/-/;s/\\/-/;s/---/-/')
	fi
	ARK_MOD_NAME_DEPRECATED=$(echo "$ARK_MOD_NAME" | egrep "$DEAD_MOD")
}

INSTALL_CHECK() {
	for MODID in ${ARK_MOD_ID[@]}; do
		MOD_NAME_CHECK
		if [ ! "$ARK_MOD_NAME" = "" ] && [ ! "$ARK_MOD_NAME_NORMAL" = "" ]; then
			MOD_DOWNLOAD
			if [ -d "$STEAM_CONTENT_PATH"/"$MODID" ]; then
				if [ -d "$ARK_MOD_PATH"/ark_"$MODID" ]; then
					rm -rf "$ARK_MOD_PATH"/ark_"$MODID"/ShooterGame/Content/Mods/"$MODID"/
				fi
				DECOMPRESS
				if [ -d "$ARK_MOD_PATH"/ark_"$MODID" ]; then
					if [ "$ARK_MOD_NAME_DEPRECATED" = "" ]; then
						if [ -f "$MOD_LOG" ]; then
							local MOD_TMP_NAME=$(cat "$MOD_LOG" | grep "$MODID")
						fi
						if [ "$MOD_TMP_NAME" = "" ]; then
							echo "$MODID" >> "$MOD_LOG"
							if [ "$MODE" = "INSTALL" ] || [ "$MODE" = "INSTALLALL" ]; then
								DATABASE_STRING=$(echo "INSERT INTO addons (id, active, paddon, addon, type, folder, menudescription, configs, cmd, rmcmd, depending, resellerid) VALUES (NULL, 'Y', 'N', 'ark_$MODID', 'tool', '', 'AppID: $MODID - $ARK_MOD_NAME_NORMAL', '', '', '', '0', '0')")
								DATABASE_CONNECTION
							elif [ "$MODE" = "UPDATE" ]; then
								sed -i "/$MODID/d" "$TMP_PATH"/ark_custom_appid_tmp.log
							fi
						fi
					else
						if [ -f "$MOD_NO_UPDATE_LOG" ]; then
							local MOD_TMP_NAME=$(cat "$MOD_NO_UPDATE_LOG" | grep "$MODID" )
						fi
						if [ "$MOD_TMP_NAME" = "" ]; then
							echo "$MODID" >> "$MOD_NO_UPDATE_LOG"
							if [ "$MODE" = "INSTALL" ] || [ "$MODE" = "INSTALLALL" ]; then
								DATABASE_STRING=$(echo "INSERT INTO addons (id, active, paddon, addon, type, folder, menudescription, configs, cmd, rmcmd, depending, resellerid) VALUES (NULL, 'Y', 'N', 'ark_$MODID', 'tool', '', 'AppID: $MODID - $ARK_MOD_NAME_NORMAL', '', '', '', '0', '0')")
								DATABASE_CONNECTION
							fi
						fi
					fi
					chown -cR "$MASTERSERVER_USER":"$MASTERSERVER_USER" "$ARK_MOD_PATH"/ark_"$MODID" >/dev/null 2>&1
					chown -cR "$MASTERSERVER_USER":"$MASTERSERVER_USER" "$LOG_PATH"/* >/dev/null 2>&1
					echo "$ARK_LAST_CHANGES_DATE" > ""$MOD_LAST_VERSION"/ark_mod_id_"$MODID".txt"
					chown -cR "$MASTERSERVER_USER":"$MASTERSERVER_USER" "$MOD_LAST_VERSION" >/dev/null 2>&1
					greenMessage "Mod $ARK_MOD_NAME_NORMAL was successfully installed."
					sleep 2
				else
					echo; echo
					redMessage "Mod $ARK_MOD_NAME_NORMAL in the masteraddons Folder has not been installed!"
				fi
			else
				redMessage "ModID $MODID in the Steam Content Folder not found!"
			fi
		else
			echo "$MODID" >> "$MOD_LOG"
			redMessage "Steam Community are currently not available or ModID $MODID not known!"
			redMessage "Please try again later."
		fi
	done
}

MOD_DOWNLOAD() {
	echo; echo
	cyanonelineMessage "ARK Mod ID:   "; whiteMessage "$MODID"
	cyanonelineMessage "ARK Mod Name: "; whiteMessage "$ARK_MOD_NAME_NORMAL"
	cyanonelineMessage "Steam Download Status: "

	COUNTER=0
	while [ $COUNTER -lt 4 ]; do
		touch "$TMP_PATH"/ark_spinner
		SPINNER &
		RESULT=$(su "$MASTERSERVER_USER" -c "$STEAM_CMD_PATH +login anonymous +workshop_download_item $ARK_APP_ID $MODID validate +quit" | egrep "Success" | cut -c 1-7)

		if [ -d $MASTER_PATH/Steam/steamapps/workshop/content/$ARK_APP_ID/$MODID ]; then
			STEAM_WORKSHOP_PATH="$MASTER_PATH/Steam/steamapps/workshop"
		else
			STEAM_WORKSHOP_PATH="$MASTER_PATH/masterserver/steamCMD/steamapps/workshop"
		fi

		STEAM_CONTENT_PATH="$STEAM_WORKSHOP_PATH/content/$ARK_APP_ID"
		STEAM_DOWNLOAD_PATH="$STEAM_WORKSHOP_PATH/downloads/$ARK_APP_ID"

		if [ "$RESULT" = "Success" ] && [ -d "$STEAM_CONTENT_PATH"/"$MODID" ]; then
			if [ -f "$TMP_PATH"/ark_update_failure.log ]; then
				local TMP_ID=$(cat "$TMP_PATH"/ark_update_failure.log | grep "$MODID")
				if [ "$TMP_ID" = "" ]; then
					sed -i "/$MODID/d" "$TMP_PATH"/ark_update_failure.log
				fi
			fi
			rm -rf "$TMP_PATH"/ark_spinner
			wait $SPINNER
			greenMessage "$RESULT"
			unset RESULT
			cyanonelineMessage "Connection Attempts:   "; whiteMessage "$COUNTER"
			break
		else
			if [ "$COUNTER" = "3" ]; then
				rm -rf "$TMP_PATH"/ark_spinner
				wait $SPINNER
				if [ ! -f "$TMP_PATH"/ark_update_failure.log ]; then
					touch "$TMP_PATH"/ark_update_failure.log
				fi
				local TMP_ID=$(cat "$TMP_PATH"/ark_update_failure.log | grep "$MODID")
				if [ "$TMP_ID" = "" ]; then
					echo "$MODID" >> "$TMP_PATH"/ark_update_failure.log
				fi
				sed -i "/$MODID/d" "$TMP_PATH"/ark_custom_appid_tmp.log >/dev/null 2>&1
				redMessage "FAILURE"
				cyanonelineMessage "Connection Attempts:   "; whiteMessage "$COUNTER"
				break
			else
				rm -rf "$TMP_PATH"/ark_spinner
				wait $SPINNER
				rm -rf $STEAM_CONTENT_PATH/*
				rm -rf $STEAM_DOWNLOAD_PATH/*
				let COUNTER=$COUNTER+1
				sleep 5
			fi
		fi
	done
}

DECOMPRESS() {
	mod_appid=$ARK_APP_ID
	mod_branch=Windows
	modid=$MODID

	modsrcdir="$STEAM_CONTENT_PATH/$MODID"
	moddestdir="$ARK_MOD_PATH/ark_$MODID/ShooterGame/Content/Mods/$MODID"
	modbranch="${mod_branch:-Windows}"

	for varname in "${!mod_branch_@}"; do
		if [ "mod_branch_$modid" == "$varname" ]; then
			modbranch="${!varname}"
		fi
	done

	if [ \( ! -f "$moddestdir/.modbranch" \) ] || [ "$(<"$moddestdir/.modbranch")" != "$modbranch" ]; then
		rm -rf "$moddestdir"
	fi

	if [ -f "$modsrcdir/mod.info" ]; then
		if [ -f "$modsrcdir/${modbranch}NoEditor/mod.info" ]; then
			modsrcdir="$modsrcdir/${modbranch}NoEditor"
		fi

		find "$modsrcdir" -type d -printf "$moddestdir/%P\0" | xargs -0 -r mkdir -p

		find "$modsrcdir" -type f ! \( -name '*.z' -or -name '*.z.uncompressed_size' \) -printf "%P\n" | while read f; do
			if [ \( ! -f "$moddestdir/$f" \) -o "$modsrcdir/$f" -nt "$moddestdir/$f" ]; then
				printf "%10d  %s  " "`stat -c '%s' "$modsrcdir/$f"`" "$f"
				cp "$modsrcdir/$f" "$moddestdir/$f"
				echo -ne "\r\\033[K"
			fi
		done

		find "$modsrcdir" -type f -name '*.z' -printf "%P\n" | while read f; do
			if [ \( ! -f "$moddestdir/${f%.z}" \) -o "$modsrcdir/$f" -nt "$moddestdir/${f%.z}" ]; then
				printf "%10d  %s  " "`stat -c '%s' "$modsrcdir/$f"`" "${f%.z}"
				perl -M'Compress::Raw::Zlib' -e '
					my $sig;
					read(STDIN, $sig, 8) or die "Unable to read compressed file";
					if ($sig != "\xC1\x83\x2A\x9E\x00\x00\x00\x00"){
						die "Bad file magic";
					}
					my $data;
					read(STDIN, $data, 24) or die "Unable to read compressed file";
					my ($chunksizelo, $chunksizehi,
						$comprtotlo,  $comprtothi,
						$uncomtotlo,  $uncomtothi)  = unpack("(LLLLLL)<", $data);
					my @chunks = ();
					my $comprused = 0;
					while ($comprused < $comprtotlo) {
						read(STDIN, $data, 16) or die "Unable to read compressed file";
						my ($comprsizelo, $comprsizehi,
							$uncomsizelo, $uncomsizehi) = unpack("(LLLL)<", $data);
						push @chunks, $comprsizelo;
							$comprused += $comprsizelo;
					}
					foreach my $comprsize (@chunks) {
						read(STDIN, $data, $comprsize) or die "File read failed";
						my ($inflate, $status) = new Compress::Raw::Zlib::Inflate();
						my $output;
						$status = $inflate->inflate($data, $output, 1);
						if ($status != Z_STREAM_END) {
							die "Bad compressed stream; status: " . ($status);
						}
						if (length($data) != 0) {
							die "Unconsumed data in input"
						}
						print $output;
					}
				' <"$modsrcdir/$f" >"$moddestdir/${f%.z}"
				touch -c -r "$modsrcdir/$f" "$moddestdir/${f%.z}"
				echo -ne "\r\\033[K"
			fi
		done

		perl -e '
			my $data;
			{ local $/; $data = <STDIN>; }
			my $mapnamelen = unpack("@0 L<", $data);
			my $mapname = substr($data, 4, $mapnamelen - 1);
				$mapnamelen += 4;
			my $mapfilelen = unpack("@" . ($mapnamelen + 4) . " L<", $data);
			my $mapfile = substr($data, $mapnamelen + 8, $mapfilelen);
			print pack("L< L< L< Z8 L< C L< L<", $ARGV[0], 0, 8, "ModName", 1, 0, 1, $mapfilelen);
			print $mapfile;
			print "\x33\xFF\x22\xFF\x02\x00\x00\x00\x01";
		' $modid <"$moddestdir/mod.info" >"$moddestdir/.mod"

		if [ -f "$moddestdir/modmeta.info" ]; then
			cat "$moddestdir/modmeta.info" >>"$moddestdir/.mod"
		else
			echo -ne '\x01\x00\x00\x00\x08\x00\x00\x00ModType\x00\x02\x00\x00\x001\x00' >>"$moddestdir/.mod"
		fi

		echo "$modbranch" >"$moddestdir/.modbranch"
	fi
}

DATABASE_CONNECTION() {
	if [ ! "`ps fax | grep 'mysqld' | grep -v 'grep'`" == "" ]; then
		if [ ! $(locate htdocs/stuff/config.php) = "" ]; then
			DATABASE_CONFIG_PATH=$(locate htdocs/stuff/config.php)
			DATABASE_TMP=$(cat $DATABASE_CONFIG_PATH)
			DATABASE_HOST=$(echo "$DATABASE_TMP" | grep 'host' | awk '{print $3}' | tr -d "\r';")
			DATABASE_NAME=$(echo "$DATABASE_TMP" | grep 'db' | awk '{print $3}' | tr -d "\r';")
			DATABASE_USER=$(echo "$DATABASE_TMP" | grep 'user' | awk '{print $3}' | tr -d "\r';")
			DATABASE_PW=$(echo "$DATABASE_TMP" | grep 'pwd' | awk '{print $3}' | tr -d "\r';")

			if [ "$DATABASE_HOST" = "localhost" ]; then
				unset DATABASE_HOST
				DATABASE_HOST="127.0.0.1"
			fi

			if [ "$MODE" = "INSTALL" -o "$MODE" = "INSTALLALL" ]; then
				echo
				cyanonelineMessage "Database Host: "; whiteMessage "$DATABASE_HOST"
				cyanonelineMessage "Database Name: "; whiteMessage "$DATABASE_NAME"
				cyanonelineMessage "Database User: "; whiteMessage "$DATABASE_USER"
				echo; echo;	tput cnorm
				printf "Database connection details correct [Y/N]?: "; read -n1 ANSWER
				tput civis
				case $ANSWER in
					y|Y|j|J)
						DATABASE_LOGIN_CHECK=$(mysql -h "$DATABASE_HOST" -u "$DATABASE_USER" -p"$DATABASE_PW" -e "exit")
						if [ ! "$DATABASE_LOGIN_CHECK" = "0" ]; then
							mysql -h "$DATABASE_HOST" -u "$DATABASE_USER" -p"$DATABASE_PW" -e "USE $DATABASE_NAME; $DATABASE_STRING"
							echo
							greenMessage "Database entry successfully entered"
							echo; echo
						else
							echo; echo;	redMessage "Database Login failure!"
							echo
							yellowMessage "You must self Import the XML Files into your Webinterface"
							CREATE_WI_IMPORT_FILE
						fi;;
					n|N)
						echo; echo
						yellowMessage "You must self Import the XML Files into your Webinterface"
						CREATE_WI_IMPORT_FILE;;
					*)
						ERROR; DATABASE_CONNECTION;;
				esac
			else
				DATABASE_LOGIN_CHECK=$(mysql -h "$DATABASE_HOST" -u "$DATABASE_USER" -p"$DATABASE_PW" -e "exit")
				if [ ! "$DATABASE_LOGIN_CHECK" = "0" ]; then
					mysql -h "$DATABASE_HOST" -u "$DATABASE_USER" -p"$DATABASE_PW" -e "USE $DATABASE_NAME; $DATABASE_STRING"
				else
					echo; echo
					redMessage "Database Login failure!"
					FINISHED
				fi
			fi
		else
			if [ "$MODE" = "INSTALL" -o "$MODE" = "INSTALLALL" ]; then
				echo; echo
				redMessage "Easy-WI Webinterface Database Config not Found!"
				echo
				yellowMessage "You must self Import the XML Files into your Webinterface"
				CREATE_WI_IMPORT_FILE
			fi
		fi
	else
		if [ "$MODE" = "INSTALL" -o "$MODE" = "INSTALLALL" ]; then
			echo; echo
			redMessage "Database Server not Online!"
			echo
			yellowMessage "You must self Import the XML Files into your Webinterface"
			CREATE_WI_IMPORT_FILE
		fi
	fi
}

CREATE_WI_IMPORT_FILE() {
	if [ ! -d "$EASYWI_XML_FILES" ]; then
		mkdir "$EASYWI_XML_FILES"
	fi

	echo '<?xml version="1.0" encoding="utf-8"?>
<addon>
  <active>Y</active>
  <paddon>N</paddon>
  <addon>'ark_$MODID'</addon>
  <type>tool</type>
  <folder/>
  <menudescription>AppID: '$MODID' - '$ARK_MOD_NAME_NORMAL'</menudescription>
  <configs/>
  <cmd/>
  <rmcmd/>
</addon>' > "$EASYWI_XML_FILES"/"$ARK_MOD_NAME".xml

	chown -cR "$MASTERSERVER_USER":"$MASTERSERVER_USER" "$EASYWI_XML_FILES" >/dev/null 2>&1
	echo
	cyanMessage "Easy-WI XML Import Files under $EASYWI_XML_FILES/ created."
	cyanMessage 'Import Files in the Webinterface under "Gameserver -> Addons -> Add Gameserver Addons".'
}

QUESTION1() {
	echo; echo;	tput cnorm
	printf "additional ModID installing [Y/N]?: "; read -n1 ANSWER
	tput civis
	case $ANSWER in
		y|Y|j|J)
			INSTALL;;
		n|N)
			FINISHED;;
		*)
			ERROR; QUESTION1;;
	esac
}

QUESTION2() {
	echo; echo; tput cnorm
	printf "Want to install a ModID [Y/N]?: "; read -n1 ANSWER
	tput civis
	case $ANSWER in
		y|Y|j|J)
			INSTALL;;
		n|N)
			FINISHED;;
		*)
			ERROR; QUESTION2;;
	esac
}

QUESTION3() {
	echo; echo;	tput cnorm
	printf "additional ModID uninstalling [Y/N]?: "; read -n1 ANSWER
	tput civis
	case $ANSWER in
		y|Y|j|J)
			echo; UNINSTALL;;
		n|N)
			FINISHED;;
		*)
			ERROR; QUESTION3;;
	esac
}

QUESTION4() {
	MODID="$ARK_MOD_ID"
	MOD_NAME_CHECK
	echo; echo
	cyanonelineMessage "ARK Mod ID:   "; whiteMessage "$ARK_MOD_ID"
	cyanonelineMessage "ARK Mod Name: "; whiteMessage "$ARK_MOD_NAME_NORMAL"
	echo; tput cnorm
	printf "Are the details correct? [Y/N]?: "; read -n1 ANSWER
	tput civis
	case $ANSWER in
		y|Y|j|J)
			echo;;
		n|N)
			echo; echo; redMessage 'Your Answer is "No" ... redirect to Menu.'; sleep 3; tput cnorm; MENU;;
		*)
			ERROR; QUESTION4;;
	esac
}

QUESTION5() {
	echo; echo;	tput cnorm
	printf "Installing Mod Autoupdater [Y/N]?: "; read -n1 ANSWER
	tput civis
	case $ANSWER in
		y|Y|j|J)
			UPDATER_INSTALL;;
		n|N)
			FINISHED;;
		*)
			ERROR; QUESTION5;;
	esac
}

QUESTION6() {
	echo; echo
	tput cnorm
	printf 'ModID in "not Update List" adding [Y/N]?: '; read -n1 ANSWER
	tput civis
	case $ANSWER in
		y|Y|j|J)
			sed -i "/$MODID/d" "$MOD_BACKUP_LOG" >/dev/null 2>&1
			CHECK_ID="cat "$MOD_NO_UPDATE_LOG" | grep "$MODID""
			if [ "$CHECK_ID" = "" ]; then
				echo "$MODID" >> "$MOD_NO_UPDATE_LOG"
			fi;;
		n|N)
			continue;;
		*)
			ERROR; QUESTION6;;
	esac
}

QUESTION7() {
	echo
	echo "Install all Mode - ModID List:"
	echo
	for MODID in ${ARK_MOD_ID[@]}; do
		MOD_NAME_CHECK
		echo
		cyanonelineMessage "ARK Mod ID:   "; whiteMessage "$ARK_MOD_ID"
		cyanonelineMessage "ARK Mod Name: "; whiteMessage "$ARK_MOD_NAME_NORMAL"
	done
	echo; echo; tput cnorm
	printf "Want to install all Mod IDs [Y/N]?: "; read -n1 ANSWER
	tput civis
	case $ANSWER in
		y|Y|j|J)
			echo;;
		n|N)
			FINISHED;;
		*)
			ERROR; QUESTION7;;
	esac
}

SPINNER() {
	local delay=0.45
	local spinstr='|/-\'
	while [ -f "$TMP_PATH"/ark_spinner ]; do
		local temp=${spinstr#?}
		printf "[%c]  " "$spinstr"
		local spinstr=$temp${spinstr%"$temp"}
		sleep $delay
		printf "\b\b\b\b\b"
	done
	printf "    \b\b\b\b"
}

CLEANFILES() {
	rm -rf "$STEAM_WORKSHOP_PATH"
	if [ -f "$TMP_PATH"/ark_custom_appid_tmp.log ]; then
		rm -rf "$TMP_PATH"/ark_custom_appid_tmp.log
	fi
	if [ -f "$TMP_PATH"/ark_spinner ]; then
		rm -rf "$TMP_PATH"/ark_spinner
	fi
	if [ -f "$TMP_PATH"/ark_update_failure.log ]; then
		rm -rf "$TMP_PATH"/ark_update_failure.log
	fi
}

FINISHED() {
	CLEANFILES
	if [ -f "$TMP_PATH"/ark_mod_updater_status ]; then
		rm -rf "$TMP_PATH"/ark_mod_updater_status
	fi
	echo; echo
	tput cnorm
	if [ "$DEBUG" == "ON" ]; then
		set +x
	fi
	yellowMessage "Thanks for using this script and have a nice Day."
	HEADER
	echo
	exit 0
}

ERROR() {
	echo; echo
	redMessage "It was not a valid input detected!"
	redMessage "Please wait..."
	sleep 3
}

HEADER() {
	echo
	cyanMessage "###################################################"
	cyanMessage "####         EASY-WI - www.Easy-WI.com         ####"
	cyanMessage "####        ARK - Mod / Content Manager        ####"
	cyanMessage "####               Version: $CURRENT_MANAGER_VERSION              ####"
	cyanMessage "####                    by                     ####"
	cyanMessage "####                Lacrimosa99                ####"
	cyanMessage "####         www.Devil-Hunter-Clan.de          ####"
	cyanMessage "####      www.Devil-Hunter-Multigaming.de      ####"
	cyanMessage "###################################################"
	echo
}

greenMessage() {
	echo -e "\\033[32;1m${@}\033[0m"
}

redMessage() {
	echo -e "\\033[31;1m${@}\033[0m"
}

cyanMessage() {
	echo -e "\\033[36;1m${@}\033[0m"
}

yellowMessage() {
	echo -e "\\033[33;1m${@}\033[0m"
}

whiteMessage() {
	echo -e "\\033[1m${@}\033[0m"
}

cyanonelineMessage() {
	echo -en "\\033[36;1m${@}\033[0m"
}

whiteonelineMessage() {
	echo -e "\\033[1m${@}\033[0m"
}

### Start ###
if [ "$DEBUG" == "ON" ]; then
	set -x
fi

id | grep "uid=0(" > /dev/null
if [ $? != "0" ]; then
	uname -a | grep -i CYGWIN > /dev/null
	if [ $? != "0" ]; then
		echo
		redMessage "Still not root, aborting!"
		redMessage 'You must User "root", to run this Script!'
		echo
		echo
		exit 1
	fi
fi

PRE_CHECK
