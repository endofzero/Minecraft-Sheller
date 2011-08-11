#!/bin/bash
# version 2.5 (4/4/11)
# original author : Relliktsohg
# continued contributions: Maine, endofzero
# dopeghoti, demonspork, robbiet480, sandain, orospakr, jdiamond
# https://github.com/endofzero/Minecraft-Sheller

# This is the path to where the location of the config.sh file resides.
# If no file is found, the Configuration settings in this file will be used. 
CONFIG_PATH=/home/minecraft/minecraft-Sheller

#	Configuration
# Main
WORLD_NAME="world"
OFFLINE_NAME=$WORLD_NAME-offline
MC_PATH=/home/minecraft
SCREEN_NAME="minecraft"
MEMMAX=1536
DISPLAY_ON_LAUNCH=0
SERVER_OPTIONS=""

# Modifications
SERVERMOD=1
MODJAR="craftbukkit-0.0.1-SNAPSHOT.jar"
RUNECRAFT=1
MCMYADMIN=1


# Backups
BKUP_PATH=$MC_PATH/backup
BKUP_DAYS_INCR=2
BKUP_DAYS_FULL=5
BACKUP_FULL_LINK=${BKUP_PATH}/${WORLD_NAME}_full.tgz
BACKUP_INCR_LINK=${BKUP_PATH}/${WORLD_NAME}_incr.tgz

# Logs
LOG_TDIR=/var/www/minecraft/logs
LOGS_DAYS=14

# Mapping
CARTO_PATH=$MC_PATH/carto
MAPS_PATH=/var/www/minecraft/maps
CARTO_OPTIONS="-q -s -m 4"
BIOME_PATH=/home/minecraft/BiomeExtractor
MAP_CHANGES=1

MCOVERVIEWER_PATH=$MC_PATH/Overviewer/
MCOVERVIEWER_MAPS_PATH=/var/www/minecraft/maps/Overview/
MCOVERVIEWER_OPTIONS="--rendermodes=lighting,night"

# 	End of configuration
[ -f $CONFIG_PATH/config.sh ] && source $CONFIG_PATH/config.sh

# Make sure that Java, Perl, GNU Screen, and GNU Wget are installed.
JAVA=$(which java)
PERL=$(which perl)
SCREEN=$(which screen)
WGET=$(which wget)
if [ ! -e $JAVA ]; then
        printf "Java not found!\n"
        printf "Try installing this with:\n"
        printf "sudo apt-get install openjdk-6-jre\n"
        exit 1
fi
if [ ! -e $PERL ]; then
        printf "Perl not found!\n"
        printf "Try installing this with:\n"
        printf "sudo apt-get install perl\n"
        exit 1
fi
if [ ! -e $SCREEN ]; then
        printf "GNU Screen not found!\n"
        printf "Try installing this with:\n"
        printf "sudo apt-get install screen\n"
        exit 1
fi
if [ ! -e $WGET ]; then
        printf "GNU Wget not found!\n"
        printf "Try installing this with:\n"
        printf "sudo apt-get install wget\n"
        exit 1
fi

	if [[ -e $MC_PATH/server.log.lck ]]; then
		#       ps -e | grep java | wc -l
		ONLINE=1
	else
		ONLINE=0
	fi

#	Get the PID of our Java process for later use.  Better
#	than just killing the lowest PID java process like the
#	original verison did, but still non-optimal.
#
#	Explanation: 
#
#	Find the PID of our screen that's running Minecraft.
#	Then, use PS to find children of that screen whose
#	command is 'java'.

# SCREEN_PID=$(screen -list | grep $SCREEN_NAME | grep -iv "No sockets found" | head -n1 | sed "s/^\s//;s/\.$SCREEN_NAME.*$//")
USERNAME=$(whoami)
SCREEN_PID=$(screen -ls $SCREEN_NAME | $PERL -ne 'if ($_ =~ /^\t(\d+)\.$SCREEN_NAME.*$/) { print $1; }')
#        echo "$SCREEN_PID $JAVA_PID"

if [[ -z $SCREEN_PID ]]; then
	#	Our server seems offline, because there's no screen running.
	#	Set MC_PID to a null value.
	MC_PID=''
else
#	MC_PID=$(ps $SCREEN_PID -F -C java -o pid,ppid,comm | tail -1 | awk '{print $2}')
	MC_PID=$(ps -a -u $USERNAME -o pid,ppid,comm | $PERL -ne 'if ($_ =~ /^\s*(\d+)\s+'$SCREEN_PID'\s+java/) { print $1; }')
fi

display() {
	screen -x $SCREEN_NAME
}

server_launch() {
	echo "Launching minecraft server..."
	if [[ 1 -eq $MCMYADMIN && -f $MC_PATH/McMyAdmin.exe ]]; then
	    echo "Starting McMyAdmin..."
	    cd $MC_PATH
		screen -dmS $SCREEN_NAME mono McMyAdmin.exe
	else	    
    	if [[ 1 -eq $SERVERMOD ]]; then
    		echo $MODJAR
    		cd $MC_PATH
    		screen -dmS $SCREEN_NAME java -server -Xmx${MEMMAX}M -Xincgc $SERVER_OPTIONS -jar $MODJAR nogui
    		sleep 1
    	else
    		echo "minecraft_server.jar"
    		cd $MC_PATH
    		screen -dmS $SCREEN_NAME java -server -Xmx${MEMMAX}M -Xincgc $SERVER_OPTIONS -jar minecraft_server.jar nogui
    		sleep 1
    	fi
    fi
}

server_stop() {
	echo "Stopping minecraft server..."
	screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "/quit.\r")"
	sleep 5
}

sync_offline() {
        if [[ -e $MC_PATH/synclock ]]; then
        	echo "Previous sync hasn't completed or has failed"
        else
                touch $MC_PATH/synclock

                echo "Sync in progress..."

                if [[ 1 -eq $ONLINE ]]; then
                	echo "Issuing save-all command, wait 5s...";
                        screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "save-all\r")"
                        sleep 5
                        echo "Issuing save-off command..."
                        screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "save-off\r")"
                        sleep 1
                        screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "say World sync in progress, saving is OFF.\r")"
                fi

                        mkdir -p $MC_PATH/$OFFLINE_NAME/
                        rsync -a $MC_PATH/$WORLD_NAME/ $MC_PATH/$OFFLINE_NAME/
                        WORLD_SIZE=$(du -s $MC_PATH/$WORLD_NAME/ | sed s/[[:space:]].*//g)
                        OFFLINE_SIZE=$(du -s $MC_PATH/$OFFLINE_NAME/ | sed s/[[:space:]].*//g)
                        echo "WORLD  : $WORLD_SIZE KB"
                        echo "OFFLINE: $OFFLINE_SIZE KB"

                        if [[ 1 -eq $ONLINE ]]; then
                        	echo "Issuing save-on command..."
                                screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "save-on\r")"
                                sleep 1
                                screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "say World sync is complete, saving is ON.\r")"
                fi
                        rm $MC_PATH/synclock
                        echo "Sync is complete"
        fi
}

if [[ $# -gt 0 ]]; then
	case "$1" in
		#################################################################
		"status")
			if [[ 1 -eq $ONLINE ]]; then
				echo "Minecraft server seems ONLINE."
			else
				echo "Minecraft server seems OFFLINE."
			fi
			;;
		#################################################################
		"start")
			if [[ 1 -eq $ONLINE ]]; then
				echo "Server seems to be already running !"
				case $2 in
					"force")
						#	TODO:
						#	Still needs work, but at least we try
						#	to use the PID we grabbed earlier.
						#	The fallback is still to blindly
						#	kill the lowest-PID Java process running
						#	on the 	server.  This is very bad form.
						if [[ -z $MC_PID ]]; then
							kill $(ps -e | grep java | cut -d " " -f 1)
						else
							kill $MC_PID
						fi
						rm -fr $MC_PATH/*.log.lck 2> /dev/null/;;
				esac
			else
				server_launch
				if [[ 1 -eq $DISPLAY_ON_LAUNCH ]]; then
					display
				fi
			fi
			;;
		#################################################################
		"stop")
			if [[ 1 -eq $ONLINE ]]; then
				server_stop
			else
				echo "Server seems to be offline..."
				case $2 in
					"force")
						echo "Forcing server to stop if it's lying.."
						#	TODO:
						#	Still needs work, but at least we try
						#	to use the PID we grabbed earlier.
						#	The fallback is still to blindly
						#	kill the lowest-PID Java process running
						#	on the 	server.  This is very bad form.
						if [[ -z $MC_PID ]]; then
							kill $(ps -e | grep java | cut -d " " -f 1)
						else
							kill $MC_PID
						fi
						rm -fr $MC_PATH/*.log.lck 2> /dev/null/
					;;
				esac
			fi
			;;
		#################################################################
		"restart")
			if [[ 1 -eq $ONLINE ]]; then
				case $2 in
					"warn")
						echo "30 Second Warning."
						screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "say Server will restart in 30s !\r")"
						sleep 20
						echo "10 Second Warning."
						screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "say Server will restart in 10s !\r")"
						sleep 10
					;;
				esac
				server_stop
			fi
			server_launch
			if [[ 1 -eq $DISPLAY_ON_LAUNCH ]]; then
				display
			fi
			;;
		#################################################################
		"say")
			if [[ 1 -eq $ONLINE ]]; then
				screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "say $*\r")"
				sleep 1
			else
				echo "Server seems to be offline..."
			fi
			;;
		#################################################################
		"tell")
			if [[ 1 -eq $ONLINE ]]; then
				screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "tell $2 $*\r")"
				sleep 1
			else
				echo "Server seems to be offline..."
			fi
			;;
		#################################################################
		"sync")
			if [[ "purge" == $2 ]]; then
        	        	echo "Purging offline folder..."
				rm -rf $MC_PATH/$OFFLINE_NAME/
				echo "Purge Complete"
			fi
			sync_offline
			;;
		#################################################################
		"logs")
			mkdir -p $LOG_TDIR
			cd $LOG_TDIR

			case $2 in
				"clean")
					#Move all old log folders into the backup directory based on $LOGS_DAYS
					mkdir -p $BKUP_PATH/logs
					find $LOG_TDIR -type d -mtime +$LOGS_DAYS -print | xargs -I xxx mv xxx $BKUP_PATH/logs/
				;;
			esac

			DATE=$(date +%Y-%m-%d)
			LOG_NEWDIR=$DATE-logs
			if [[ -e $LOG_TDIR/$LOG_NEWDIR ]]; then
				rm $LOG_TDIR/$LOG_NEWDIR/*
			else
				mkdir $LOG_TDIR/$LOG_NEWDIR
			fi

			DATE=$(date +%d-%m-%Hh%M)
			LOG_TFILE=logs-$DATE.log

					cd $MC_PATH
					cat server.log >> $LOG_TDIR/$LOG_NEWDIR/$LOG_TFILE

			if [[ -e $LOG_TDIR/ip-list.log ]]; then
				cat $LOG_TDIR/ip-list.log | sort | uniq > $LOG_TDIR/templist.log
			fi

			cat $LOG_TDIR/$LOG_NEWDIR/$LOG_TFILE | egrep '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.+logged in'  | sed -e 's/.*\[INFO\]\s//g' -e 's/\[\//\t/g' -e 's/:.*//g' >> $LOG_TDIR/templist.log
			cat $LOG_TDIR/templist.log | sort | uniq -w 4 > $LOG_TDIR/ip-list.log
			rm $LOG_TDIR/templist.log

			cat $LOG_TDIR/$LOG_NEWDIR/$LOG_TFILE | egrep 'logged in|lost connection' | sed -e 's/.*\([0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\).\[INFO\].\([a-zA-Z0-9_]\{1,\}\).\{1,\}logged in/\1\t\2 : connected/g' -e 's/.*\([0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\).\[INFO\].\([a-zA-Z0-9_]\{1,\}\).lost connection.*/\1\t\2 : disconnected/g' >> $LOG_TDIR/$LOG_NEWDIR/connexions-$DATE.log

			cat $LOG_TDIR/$LOG_NEWDIR/$LOG_TFILE | egrep '<[a-zA-Z0-9_]+>|\[CONSOLE\]' | sed -e 's/.*\([0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\).\[INFO\]./\1 /g' >> $LOG_TDIR/$LOG_NEWDIR/chat-$DATE.log

			cat $LOG_TDIR/$LOG_NEWDIR/$LOG_TFILE | egrep 'Internal exception|error' | sed -e 's/.*\([0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\).\[INFO\]./\1\t/g' >> $LOG_TDIR/$LOG_NEWDIR/errors-$DATE.log
			;;
		#################################################################
		"backup")

			if [[ -e $BKUP_PATH/$WORLD_NAME.lock ]]; then
				echo "Backup already in progress.  Aborting."
				exit 1
			else
				touch $BKUP_PATH/$WORLD_NAME.lock
			fi

			if [[ ! -d $BKUP_PATH  ]]; then
				if ! mkdir -p $BKUP_PATH; then
					echo "Backup path $BKUP_PATH does not exist and I could not create the directory!"
					rm $BKUP_PATH/$WORLD_NAME.lock
					exit 1
				fi
			fi

			cd $BKUP_PATH

			if [[ -e $MC_PATH/$WORLD_NAME ]]; then
				if [[ $ONLINE -eq 1 ]]; then
					echo "Server running, warning players : backup in 10s."
					screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "say Backing up the map in 10s\r")"
					sleep 10
					screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "say Now backing up the map...\r")"
					echo "Issuing save-all command, wait 5s..."
					screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "save-all\r")"
					sleep 5
					echo "Issuing save-off command..."
					screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "save-off\r")"
					sleep 1
				fi

				cd $BKUP_PATH

				DATE=$(date +%Y-%m-%d-%Hh%M)
				FILENAME=$WORLD_NAME-$DATE
				BACKUP_FILES=$BKUP_PATH/list.$DATE

				if [[ full == $2 ]]; then
					# If full flag set, Make full backup, and remove old incrementals
					FILENAME=$FILENAME-full.tgz

					# Remove incrementals older than $BKUP_DAYS_INCR
					# Remove full archives older than $BKUP_DAYS_FULL
					find ./$WORLD_NAME-*-incr.tgz -type f -mtime +$BKUP_DAYS_INCR -print > purgelist
					find ./$WORLD_NAME-*-full.tgz -type f -mtime +$BKUP_DAYS_FULL -print >> purgelist
					rm -f $(cat purgelist) purgelist

					# Now make our full backup
					pushd $MC_PATH
					find $WORLD_NAME -type f -print > $BACKUP_FILES
					tar -zcf $BKUP_PATH/$FILENAME --files-from=$BACKUP_FILES
					popd

					rm -f $BACKUP_FULL_LINK $BACKUP_INCR_LINK
					ln -s $FILENAME $BACKUP_FULL_LINK
				else
					# Make incremental backup
					FILENAME=$FILENAME-incr.tgz

					pushd $MC_PATH
					find $WORLD_NAME -newer $BACKUP_FULL_LINK -type f -print > $BACKUP_FILES
					tar -zcf $BKUP_PATH/$FILENAME --files-from=$BACKUP_FILES
					popd

					rm -f $BACKUP_INCR_LINK
					ln -s $FILENAME $BACKUP_INCR_LINK
				fi

				rm -f $BACKUP_FILES

				if [[ 1 -eq $ONLINE ]]; then
					echo "Issuing save-on command..."
					screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "save-on\r")"
					sleep 1
					screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "say Backup is done, have fun !\r")"
				fi
				echo "Backup process is over."
			else
				echo "The world \"$WORLD_NAME\" does not exist.";
			fi
			rm $BKUP_PATH/$WORLD_NAME.lock
			;;
		#################################################################
		"cartography")
			if [[ -e $MC_PATH/cartolock ]]; then
				echo "Previous cartography run hasn't completed or has failed"
			else
				touch $MC_PATH/cartolock

				if [[ "sync" == $2 ]]; then
					sync_offline
				fi

				if [[ -e $CARTO_PATH ]]; then
					if [[ -e $MC_PATH/$WORLD_NAME ]]; then

						mkdir -p $MAPS_PATH

						DATE=$(date +%Y-%m-%d-%Hh%M)
						FILENAME=$WORLD_NAME-map-$DATE
						cd $CARTO_PATH
						echo "Cartography in progress..."
						./c10t -w $MC_PATH/$OFFLINE_NAME/ -o $FILENAME.png $CARTO_OPTIONS
						mv *.png $MAPS_PATH
						if [ 1 -eq $MAP_CHANGES ]; then
			                                rm -f $MAPS_PATH/previous.png
                        			        ln $MAPS_PATH/current.png $MAPS_PATH/previous.png
                                			rm -f $MAPS_PATH/current.png
                                			ln $MAPS_PATH/$FILENAME.png $MAPS_PATH/current.png
						fi
						cd $MC_PATH
						echo "Cartography is done."
						if [ 1 -eq $MAP_CHANGES ]; then
							echo "Generating changes."
							if [[ -e $MAPS_PATH/previous.png ]]; then
			                                        cd $MAPS_PATH
								mkdir changes
			                                        export RTMP=/tmp/makechanges.$$.
			                                        compare previous.png current.png $RTMP.1.tga
                        			                convert -transparent white $RTMP.1.tga $RTMP.2.tga
			                                        composite -quality 100 $RTMP.2.tga previous.png changes/changes-$FILENAME.png
								rm -f $MAPS_PATH/new.png
			                                        ln changes/changes-$FILENAME.png new.png
                        			                rm -rf previous.png $RTMP.*
							fi
						fi
					else
						echo "The world \"$WORLD_NAME\" does not exist."
					fi
				else
					echo "The path to cartographer seems to be wrong."
				fi
				rm $MC_PATH/cartolock
			fi
			;;
		#################################################################
		"biome")
			if [[ -e $BIOME_PATH ]]; then
				if [[ -e $MC_PATH/$WORLD_NAME ]]; then

					if [[ "sync" == $2 ]]; then
						sync_offline
					fi

					echo "Biome extraction in progress..."
					java -jar $BIOME_PATH/MinecraftBiomeExtractor.jar -nogui $MC_PATH/$OFFLINE_NAME/
					echo "Biome extraction is complete"

				else
					echo "The world \"$WORLD_NAME\" does not exist."
				fi
			else
				echo "The path to MinecraftBiomeExtractor.jar seems to be wrong."
			fi
			;;
		#################################################################
		"overviewer")
			if [[ -e $MC_PATH/overviewlock ]]; then
				echo "Previous overview run hasn't completed or has failed"
			else
				touch $MC_PATH/overviewlock

				if [[ "sync" == $2 ]]; then
					sync_offline
				fi

				if [[ -e $MCOVERVIEWER_PATH ]];  then
					if [[ -e $MC_PATH/$WORLD_NAME ]]; then

						mkdir -p $MCOVERVIEWER_MAPS_PATH

						echo "Minecraft-Overviewer in progress..."
						python $MCOVERVIEWER_PATH/overviewer.py $MCOVERVIEWER_OPTIONS $MC_PATH/$OFFLINE_NAME $MCOVERVIEWER_MAPS_PATH
						echo "Minecraft-Overviewer is done."

					else
						echo "The world \"$WORLD_NAME\" does not exist.";
					fi
				else
					echo "The path to Minecraft-Overviewer seems to be wrong."
				fi
				rm $MC_PATH/overviewlock
			fi
			;;
		#################################################################
		"update")
			if [[ 1 -eq $ONLINE ]]; then
				server_stop
			fi

			mkdir -p $BKUP_PATH

			echo "Backing up current binaries..."
			DATE=$(date +%Y-%m-%d)
			cd $MC_PATH
			if [[ 1 -eq $SERVERMOD ]]; then
				tar -czf minecraft_server-$DATE.tar.gz minecraft_server.jar $MODJAR
#				rm craftbukkit.jar
			else
				tar -czf minecraft_server-$DATE.tar.gz minecraft_server.jar
			fi
			mv minecraft_server-$DATE.tar.gz $BKUP_PATH

			echo "Downloading new binaries..."
			wget -N http://www.minecraft.net/download/minecraft_server.jar
			if [[ 1 -eq $SERVERMOD ]]; then
				echo "Downloading Bukkit..."
    			if [[ 1 -eq $MCMYADMIN ]]; then
		            # McMyAdmin requires this file to be named craftbukkit.jar
        	        wget -N -O craftbukkit.jar http://ci.bukkit.org/job/dev-CraftBukkit/promotion/latest/Recommended/artifact/target/craftbukkit-0.0.1-SNAPSHOT.jar
                else
    				wget -N http://ci.bukkit.org/job/dev-CraftBukkit/promotion/latest/Recommended/artifact/target/craftbukkit-0.0.1-SNAPSHOT.jar
    			fi
			fi
			if [[ 1 -eq $RUNECRAFT ]];  then
				if [[ 1 -eq $SERVERMOD ]];  then
					echo "Downloading Runecraft..."
					cd $MC_PATH/plugins/
					wget -N http://llama.cerberusstudios.net/runecraft/runecraft_latest.jar
				else
					echo "Downloading Runecraft..."
					mkdir -p ModTmp
					cd ModTmp/
					wget -N http://llama.cerberusstudios.net/runecraft_latest.zip
					unzip runecraft_latest.zip
					jar uvf $MC_PATH/minecraft_server.jar *.class
					cd $MC_PATH
					rm -rf ModTmp 
				fi
			fi

			server_launch
			if [[ 1 -eq $DISPLAY_ON_LAUNCH ]]; then
				display
			fi
			;;
		#################################################################
		*)
			echo "Usage : minecraft <status | start [force] | stop | restart [warn] | say 'message' | tell user 'message' | logs [clean]"
			echo "backup [full] | sync [purge] | cartography [sync] | biome [sync] | overviewer [sync] | update>"
			;;
	esac

else
	if [[ 1 -eq $ONLINE ]]; then
		display
	else
		echo "Minecraft server seems to be offline..."
	fi
fi
exit 0
