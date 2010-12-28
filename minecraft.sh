#!/bin/bash
# original author : Relliktsohg
# continued contributions: Maine, endofzero
# dopeghoti

#	Configuration

# Main
WORLD_NAME="world"
OFFLINE_NAME=$WORLD_NAME-offline
MC_PATH=/home/minecraft
SCREEN_NAME="minecraft"
MEMMAX=1536
MEMALOC=1024
DISPLAY_ON_LAUNCH=0
SERVER_OPTIONS=""

# Modifications
SERVERMOD=0
RUNECRAFT=0

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

MCOVERVIEWER_PATH=$MC_PATH/Overviewer/
MCOVERVIEWER_MAPS_PATH=/var/www/minecraft/maps/Overview/
MCOVERVIEWER_CACHE_PATH=/var/www/minecraft/maps/Overview/cache/
MCOVERVIEWER_OPTIONS="--lighting"

# 	End of configuration

if [[ 1 -eq $SERVERMOD  ]]; then
	locks=$(ls $MC_PATH/logs/*.log.lck 2> /dev/null | wc -l)
	if [[ "0" != "$locks" ]]; then
		ONLINE=1
	else
		ONLINE=0
	fi
else
	if [[ -e $MC_PATH/server.log.lck ]]; then
		#       ps -e | grep java | wc -l
		ONLINE=1
	else
		ONLINE=0
	fi
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

SCREEN_PID=$(screen -ls | grep $SCREEN_NAME | head -n1 | sed "s/^\s//;s/\.$SCREEN_NAME.*$//")

if [[ -z $SCREEN_PID ]]; then
	#	Our server seems offline, because there's no screen running.
	#	Set MC_PID to a null value.
	MC_PID=''
else
	MC_PID=$(ps --ppid $SCREEN_PID -F -C java | tail -1 | awk '{print $2}')
fi

display() {
	screen -x $SCREEN_NAME
}

server_launch() {
	echo "Launching minecraft server..."
	if [[ 1 -eq $SERVERMOD ]]; then
		echo "Minecraft_Mod.jar"
		cd $MC_PATH
		screen -dmS $SCREEN_NAME java -server -Xmx${MEMMAX}M -Xms${MEMALOC}M -Djava.net.preferIPv4Stack=true $SERVER_OPTIONS -jar Minecraft_Mod.jar nogui
		sleep 1
	else
		echo "minecraft_server.jar"
		cd $MC_PATH
		screen -dmS $SCREEN_NAME java -server -Xmx${MEMMAX}M -Xms${MEMALOC}M -Djava.net.preferIPv4Stack=true $SERVER_OPTIONS -jar minecraft_server.jar nogui
		sleep 1
	fi		
}
	
server_stop() {
	echo "Stopping minecraft server..."
	screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "stop.\r")"
	sleep 5
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
						screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "say Server will restart in 30s !\r")"
						sleep 20
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
				screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "say $2\r")"
				sleep 1
			else
				echo "Server seems to be offline..."
			fi
		;;
		#################################################################
		"sync")
			if [[ -e $MC_PATH/synclock ]]; then
				echo "Previous run hasn't completed or has failed"
			else
				touch $MC_PATH/synclock

				if [[ 1 -eq $ONLINE ]]; then
        	                	echo "Issuing save-all command, wait 5s...";
	                                screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "save-all\r")"
	                                sleep 5
	                                echo "Issuing save-off command..."
	                                screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "save-off\r")"
	                                sleep 1
	                                screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "say World sync in progress, saving is OFF.\r")"
				fi

                                echo "Sync in progress..."
                                mkdir -p $MC_PATH/$OFFLINE_NAME/
                                rsync -az $MC_PATH/$WORLD_NAME/ $MC_PATH/$OFFLINE_NAME/
				WORLD_SIZE=$(du -s $MC_PATH/$WORLD_NAME/ | sed s/[[:space:]].*//g)
                                OFFLINE_SIZE=$(du -s $MC_PATH/$OFFLINE_NAME/ | sed s/[[:space:]].*//g)
				echo "WORLD  : $WORLD_SIZE KB"
				echo "OFFLINE: $OFFLINE_SIZE KB"
                                echo "Sync is complete"

                                if [[ 1 -eq $ONLINE ]]; then
                                        echo "Issuing save-on command..."
                                        screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "save-on\r")"
                                        sleep 1
                                        screen -S $SCREEN_NAME -p 0 -X stuff "$(printf "say World sync is complete, saving is ON.\r")"
                                fi
				rm $MC_PATH/synclock
			fi
			
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

			if [[ 1 -eq $SERVERMOD ]]; then
				if [[ 1 -eq $ONLINE ]]; then
					LOG_LCK=$(basename $MC_PATH/logs/*.log.lck .log.lck)
					echo "Found a log lock : $LOG_LCK"
				else
					LOG_LCK=""
				fi

				cd $MC_PATH/logs/
				for i in *; do
					if [[ $i != $LOG_LCK.log.lck ]]; then # skip du fichier lck
						cat $i >> $LOG_TDIR/$LOG_NEWDIR/$LOG_TFILE
						if [[ $i != $LOG_LCK.log ]]; then	# On ne supprime pas le fichier log courant, si le serv est en route
							rm $i
						fi
					fi
				done
				else
					cd $MC_PATH
					cat server.log >> $LOG_TDIR/$LOG_NEWDIR/$LOG_TFILE
				fi

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
			mkdir -p $BKUP_PATH
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

				if [[ "full" == $2 ]]; then
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
		;;
		#################################################################
		"cartography")
			if [[ -e $MC_PATH/cartolock ]]; then
				echo "Previous run hasn't completed or has failed"
			else
				touch $MC_PATH/cartolock
				if [[ -e $CARTO_PATH ]]; then
					if [[ -e $MC_PATH/$WORLD_NAME ]]; then

						mkdir -p $MAPS_PATH

						DATE=$(date +%d-%m-%Y-%Hh%M)
						FILENAME=$WORLD_NAME-map-$DATE
						cd $CARTO_PATH
						echo "Cartography in progress..."
						./c10t -w $MC_PATH/$OFFLINE_NAME/ -o $FILENAME.png $CARTO_OPTIONS
						mv *.png $MAPS_PATH
						cd $MC_PATH
						echo "Cartography is done."

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

					echo "Biome extraction in progress..."
					java -jar $BIOME_PATH/MinecraftBiomeExtractor.jar -nogui $MC_PATH/$OFFLINE_NAME/
					cp -ru $MC_PATH/$OFFLINE_NAME/EXTRACTEDBIOMES/ $MC_PATH/$WORLD_NAME/EXTRACTEDBIOMES/
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
				echo "Previous run hasn't completed or has failed"
			else
				touch $MC_PATH/overviewlock
				if [[ -e $MCOVERVIEWER_PATH ]];  then
					if [[ -e $MC_PATH/$WORLD_NAME ]]; then

						mkdir -p $MCOVERVIEWER_MAPS_PATH
	
						echo "Minecraft-Overviewer in progress..."
						python $MCOVERVIEWER_PATH/gmap.py $MCOVERVIEWER_OPTIONS --cachedir=$MCOVERVIEWER_CACHE_PATH $MC_PATH/$OFFLINE_NAME $MCOVERVIEWER_MAPS_PATH
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
				tar -czf minecraft_server-$DATE.tar.gz minecraft_server.jar Minecraft_Mod.jar
				rm Minecraft_Mod.jar
			else
				tar -czf minecraft_server-$DATE.tar.gz minecraft_server.jar
			fi
			mv minecraft_server-$DATE.tar.gz $BKUP_PATH

			echo "Downloading new binaries..."
			wget -N http://www.minecraft.net/download/minecraft_server.jar
			if [[ 1 -eq $SERVERMOD ]]; then
				echo "Downloading hey0's serverMod..."
				mkdir -p ModTmp
				cd ModTmp/
				wget -O Minecraft_Mod.zip http://hey0.net/get.php?dl=serverbeta
				unzip Minecraft_Mod.zip
				cp -f version.txt $MC_PATH/version.txt
				cp bin/Minecraft_Mod.jar $MC_PATH/Minecraft_Mod.jar
				cd $MC_PATH
				rm -rf ModTmp    
			fi
			if [[ 1 -eq $RUNECRAFT ]];  then
				echo "Downloading Runecraft..."
				mkdir -p ModTmp
				cd ModTmp/
				wget http://llama.cerberusstudios.net/runecraft_latest.zip
				unzip runecraft_latest.zip
				jar uvf $MC_PATH/minecraft_server.jar *.class
				cd $MC_PATH
				rm -rf ModTmp 
			fi

			server_launch
			if [[ 1 -eq $DISPLAY_ON_LAUNCH ]]; then
				display
			fi
		;;
		#################################################################
		*)
			echo "Usage : minecraft <status | start [force] | stop | restart [warn] | say 'message' | logs [clean] | backup [full] | sync | cartography | biome | overviewer | update>"
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
