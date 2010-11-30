#!/bin/bash
# original author : Relliktsohg
# Huge thanks to Maine for his incremental backup
# THanks to endofzero for his improved update routine

#	Configuration

MC_PATH=/home/minecraft
SERVERMOD=0
RUNECRAFT=0
SCREEN_NAME="minecraft"
MEMALOC=512
DISPLAY_ON_LAUNCH=1

WORLD_NAME="world"

BKUP_PATH=$MC_PATH/backup
BKUP_DAYS_INCR=2
BKUP_DAYS_FULL=5
BACKUP_FULL_LINK=${BKUP_PATH}/${WORLD_NAME}_full.tgz
BACKUP_INCR_LINK=${BKUP_PATH}/${WORLD_NAME}_incr.tgz

CARTO_PATH=$MC_PATH/carto
MAPS_PATH=/var/www/minecraftMaps
LOG_TDIR=/var/www/minecraftLogs
LOGS_DAYS=7

# 	End of configuration

if [ $SERVERMOD -eq 1 ]
then
        if [ -e $MC_PATH/logs/*.log.lck ]
        then
                ONLINE=1
        else
                ONLINE=0
        fi
else
        if [ -e $MC_PATH/server.log.lck ]
        then
                #       ps -e | grep java | wc -l
                ONLINE=1
        else
                ONLINE=0
        fi
fi

display() {
	screen -R $SCREEN_NAME
}

server_launch() {
	echo "Launching minecraft server..."
	if [ $SERVERMOD -eq 1 ]
	then
		cd $MC_PATH; screen -m -d -S $SCREEN_NAME java -server -Xmx${MEMALOC}M -Xms${MEMALOC}M -Djava.net.preferIPv4Stack=true -jar Minecraft_Mod.jar nogui; sleep 1
	else
		cd $MC_PATH; screen -m -d -S $SCREEN_NAME java -server -Xmx${MEMALOC}M -Xms${MEMALOC}M -Djava.net.preferIPv4Stack=true -jar minecraft_server.jar nogui; sleep 1
	fi		
}
	
server_stop() {
	echo "Stopping minecraft server..."
	screen -S $SCREEN_NAME -p 0 -X stuff "`printf "stop.\r"`"; sleep 5
}

if [ $# -gt 0 ]
then
	case $1 in

	#################################################################
	"status")
		if [ $ONLINE -eq 1 ]
		then
			echo "Minecraft server seems ONLINE."
		else 
			echo "Minecraft server seems OFFLINE."
		fi;;

	#################################################################
	"start")
		if [ $ONLINE -eq 1 ]
		then
			echo "Server seems to be already running !"
			case $2 in
			"force")
				kill `ps -e | grep java | cut -d " " -f 1`
				rm -fr $MC_PATH/*.log.lck 2> /dev/null/;;
			esac
		else
			server_launch
			if [ $DISPLAY_ON_LAUNCH -eq 1 ]
			then
				display
			fi	
		fi;;

	#################################################################
    "stop")
		if [ $ONLINE -eq 1 ]
		then
			server_stop
		else
			case $2 in
			"force")
				kill `ps -e | grep java | cut -d " " -f 1`
				rm -fr $MC_PATH/*.log.lck 2> /dev/null/;;
			*)
				echo "Server seems to be offline...";;
			esac
		fi;;

	#################################################################
    "restart")
		if [ $ONLINE -eq 1 ]
		then
			case $2 in
			"warn")
				screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Server will restart in 30s !\r"`"; sleep 20
				screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Server will restart in 10s !\r"`"; sleep 10;;
			esac
			server_stop
		fi
		server_launch
		if [ $DISPLAY_ON_LAUNCH -eq 1 ]
		then
			display
		fi;;
		
	#################################################################
	"logs")
		mkdir -p $LOG_TDIR		
		cd $LOG_TDIR

		case $2 in
		"clean")
			DATE=$(date +%d-%m --date "$LOGS_DAYS day ago")
			if [ -e logs-$DATE ]
			then
				mkdir -p $BKUP_PATH/logs
				mv logs-$DATE $BKUP_PATH/logs/
			fi
		;;
		esac
		
		DATE=$(date +%d-%m)
		LOG_NEWDIR=logs-$DATE
		if [ -e $LOG_TDIR/$LOG_NEWDIR ]
		then
			rm $LOG_TDIR/$LOG_NEWDIR/*
		else
			mkdir $LOG_TDIR/$LOG_NEWDIR
		fi
			
		DATE=$(date +%d-%m-%Hh%M)
		LOG_TFILE=logs-$DATE.log
		
		if [ $SERVERMOD -eq 1 ]
		then
			if [ $ONLINE -eq 1 ]
			then
				LOG_LCK=$(basename $MC_PATH/logs/*.log.lck .log.lck)
				echo "Found a log lock : $LOG_LCK"
			else
				LOG_LCK=""
			fi

			cd $MC_PATH/logs/
			for i in *
			do
				if [ $i != $LOG_LCK.log.lck ] # skip du fichier lck
				then
					cat $i >> $LOG_TDIR/$LOG_NEWDIR/$LOG_TFILE
					if [ $i != $LOG_LCK.log ]	# On ne supprime pas le fichier log courant, si le serv est en route
					then
						rm $i
					fi
				fi
			done
		else
			cd $MC_PATH
			cat server.log >> $LOG_TDIR/$LOG_NEWDIR/$LOG_TFILE
		fi

		if [ -e $LOG_TDIR/ip-list.log ]
		then
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
			
		if [ -e $MC_PATH/$WORLD_NAME ]
		then
			if [ $ONLINE -eq 1 ]
			then 
				echo "Server running, warning players : backup in 10s."
				screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Backing up the map in 10s\r"`"; sleep 10
				screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Now backing up the map...\r"`"
				echo "Issuing save-all command, wait 5s..."
				screen -S $SCREEN_NAME -p 0 -X stuff "`printf "save-all\r"`"; sleep 5
				echo "Issuing save-off command..."
				screen -S $SCREEN_NAME -p 0 -X stuff "`printf "save-off\r"`"; sleep 1
			fi
			
			cd $BKUP_PATH

            DATE=$(date +%Y-%m-%d-%Hh%M)
            FILENAME=$WORLD_NAME-$DATE
            BACKUP_FILES=$BKUP_PATH/list.$DATE

			if test `date +%H` -eq 0 -o ! -f $BACKUP_FULL_LINK
            then
				# Make full backup, and remove old incrementals
                FILENAME=$FILENAME-full.tgz

                # Remove incrementals older than $BKUP_DAYS_INCR
                # Remove full archives older than $BKUP_DAYS_FULL
                find ./$WORLD_NAME-*-incr.tgz -type f -mtime +$BKUP_DAYS_INCR -print > purgelist
                find ./$WORLD_NAME-*-full.tgz -type f -mtime +$BKUP_DAYS_FULL -print >> purgelist
                rm -f `cat purgelist`
                rm -f purgelist

                # Now make our full backup
                pushd $MC_PATH
                find $WORLD_NAME -type f -print > $BACKUP_FILES
                tar -zcvf $BKUP_PATH/$FILENAME --files-from=$BACKUP_FILES
                popd

                rm -f $BACKUP_FULL_LINK $BACKUP_INCR_LINK
                ln -s $FILENAME $BACKUP_FULL_LINK
            else
                # Make incremental backup
                FILENAME=$FILENAME-incr.tgz

                pushd $MC_PATH
                find $WORLD_NAME -newer $BACKUP_FULL_LINK -type f -print > $BACKUP_FILES
                tar -zcvf $BKUP_PATH/$FILENAME --files-from=$BACKUP_FILES
                popd

                rm -f $BACKUP_INCR_LINK
                ln -s $FILENAME $BACKUP_INCR_LINK
            fi

            rm -f $BACKUP_FILES
			
			if [ $ONLINE -eq 1 ]
			then
				echo "Issuing save-on command..."
				screen -S $SCREEN_NAME -p 0 -X stuff "`printf "save-on\r"`"; sleep 1
				screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Backup is done, have fun !\r"`"
			fi
			echo "Backup process is over."
		else
			echo "The world \"$WORLD_NAME\" does not exist.";
		fi;;

	#################################################################
	"cartography")

		if [ -e $CARTO_PATH ]	
		then
			if [ -e $MC_PATH/$WORLD_NAME ]
			then
				if [ $ONLINE -eq 1 ]
				then
					echo "Issuing save-all command, wait 5s...";
					screen -S $SCREEN_NAME -p 0 -X stuff "`printf "save-all\r"`"; sleep 5
					echo "Issuing save-off command...";
					screen -S $SCREEN_NAME -p 0 -X stuff "`printf "save-off\r"`"; sleep 1
					screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Map cartography has begun.\r"`"
				fi
				
				mkdir -p $MAPS_PATH
				
				DATE=$(date +%d-%m-%Y-%Hh%M)
				FILENAME=$WORLD_NAME-map-$DATE
				cd $CARTO_PATH
				echo "Cartography in progress..."
				./c10t -w $MC_PATH/$WORLD_NAME/ -o $FILENAME.png -q -s
				mv *.png $MAPS_PATH
				cd $MC_PATH
				echo "Cartography is done."
				
				if [ $ONLINE -eq 1 ]
				then
					echo "Issuing save-on command..."
					screen -S $SCREEN_NAME -p 0 -X stuff "`printf "save-on\r"`"; sleep 1
					screen -S $SCREEN_NAME -p 0 -X stuff "`printf "say Map cartography is done.\r"`"
				fi

			else
				echo "The world \"$WORLD_NAME\" does not exist.";
			fi
		else
			echo "The path to cartographier seems to be wrong."
		fi;;
	
	#################################################################
	"update")
	
		if [ $ONLINE -eq 1 ]
		then
			server_stop
		fi
		
		mkdir -p $BKUP_PATH
		
		echo "Backing up current binaries..."
		DATE=$(date +%d-%m-%Y)			
		cd $MC_PATH
		if [ $SERVERMOD -eq 1 ]
		then
			tar -czf minecraft_server-$DATE.tar.gz minecraft_server.jar Minecraft_Mod.jar
			rm Minecraft_Mod.jar
		else
			tar -czf minecraft_server-$DATE.tar.gz minecraft_server.jar
		fi
		mv minecraft_server-$DATE.tar.gz $BKUP_PATH

		echo "Downloading new binaries..."
		wget -N http://www.minecraft.net/download/minecraft_server.jar
		if [ $SERVERMOD -eq 1 ]
		then
			"Downloading hey0's serverMod..."
			mkdir -p ModTmp; cd ModTmp/
			wget -O Minecraft_Mod.zip http://hey0.net/get.php?dl=serverbeta
			unzip Minecraft_Mod.zip
			cp bin/Minecraft_Mod.jar $MC_PATH/Minecraft_Mod.jar
			cd $MC_PATH; rm -rf ModTmp    
		fi
		if [ $RUNECRAFT -eq 1 ]
		then
			echo "Downloading Runecraft..."
			mkdir -p ModTmp; cd ModTmp/
			wget http://llama.cerberusstudios.net/runecraft_latest.zip
			unzip runecraft_latest.zip
			jar uvf $MC_PATH/minecraft_server.jar jt.class mm.class q.class rm.class rn.class rt.class
			cd $MC_PATH; rm -rf ModTmp 
		fi

		server_launch
		if [ $DISPLAY_ON_LAUNCH -eq 1 ]
		then
			display
		fi;;
				
	#################################################################
	*)
		echo "Usage : minecraft <status | start [force] | stop | restart [warn] | logs [clean] | backup [clean] | cartography | update>";
	esac

else
	if [ $ONLINE -eq 1 ]
	then
		display
	else
		echo "Minecraft server seems to be offline..."
	fi
fi
exit 0
