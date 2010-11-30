Requirements:
==============
Java runtime environment
Minecraft Server JAR
Screen v4.x
c10t (for cartography)
unzip (for auto updating)

Installation :
==============
- Install the required programs
#### Screen and unzip
Debian:

     sudo apt-get install screen unzip

Or:
     sudo yum install screen unzip

#### c10t
Download from the udoprog's repo:
https://github.com/udoprog/c10t

#### minecraft.sh

- copy the script into your minecraft server folder.
- allow the script to be executed 
#####     chmod +x minecraft.sh

- check the rights of the script user. Every folder specified in the 
configuration phase has to be available to him.
- edit the script to configure it (see the configuration section)

#### (optional)
- I strongly recommend using crontab to automate some of the process. I 
prefer to perform logs + cartography + server restart at 4AM 
every day. 
- The 'logs' command should always be used BEFORE a restart, as 
the restart wipes the previous logs. I'm running hey0's servermod, which 
allows to have a log history, but thats not the case for everyone.
- I also recommend setting an Internet public folder, for the maps 
images to be displayed. People on my server love this feature, as they 
know a new map is generated every day, and they can see the evolution of 
our world.
- I made an alias to be able to use 'minecraft command' instead of 
'./minecraft.sh command'. It also enables the automatic completion, if 
you type 'mine' then press tab. Much quicker =) You can do this by 
editing /home/USER/.bashrc, and adding the line:

#####     alias minecraft="/home/minecraft/minecraft.sh"

**(of course, change the path if needed)**

Considerations:
--------------

If using [Brownan's Overviewer](http://github.com/brownan/Minecraft-Overviewer) to create Google-like maps of your worlds, 
be sure you are using the --cachedir=/path/to/dir to change the location 
of the png files as you will start to take up considerable space since it
defaults to save the files inside of the world folder. This can grow backups
that are only 3mb to 99mb files. If you are not cleaning the logs, this will
start to consume a considerable amount of hard drive space.

Configuration :
===============

There are several variables to set before you can run the script for the first time.
Open minecraft.sh with a text editor, and edit the following lines, at the beginning of the file :

    MC_PATH=/home/minecraft
This is the path to your minecraft folder

    SERVERMOD=0
If you are running hey0's servermod, this needs to be set to 1 _(better logging and automatic updating of the mod)_

    RUNECRAFT=0
If you want your script to update runecraft automatically too, set this to 1

    WORLD_NAME="world"
This is the path to the world folder

    SCREEN_NAME="minecraft"
This is the name of the screen the server will be run on

    MEMALOC=1024
This is the size of RAM you want to allocate to the server

    DISPLAY_ON_LAUNCH=1
Do you want the screen to be displayed each time the server starts? 1 if yes, 0 if no.

    BKUP_PATH=$MC_PATH/backup
This is the path to the backup folder. Map backups and old log entries will go there.

    BKUP_DAYS=3
How long will the map backups be kept? _(Only used with the './minecraft.sh backup clean' command)_

    CARTO_PATH=$MC_PATH/carto
This is the path to c10t's cartography script

    MAPS_PATH=/var/www/minecraftMaps
This is the path to the world maps folder

    LOG_TDIR=/var/www/minecraftLogs
This is the path to the logs folder

    LOGS_DAYS=7
How long will the logs be kept? _(Only used with the './minecraft.sh logs clean' command)_

### Detailed Command Usage

##### ./minecraft.sh
Without arguments, the script will resume the server screen. 
(If you want to close the screen without shutting down the server, use 
CTRL+A then press D to detatch the screen)
##### ./minecraft.sh status
Tells you if the servers seems to be running, or not.
##### ./minecraft.sh start [force]
Starts the server. If you know your server is not running, but the script believe it is, use the force option.
##### ./minecraft.sh stop [force]
Self explainatory
##### ./minecraft.sh restart [warn]
If the warn option is specified, it will display a warnning 30s & 10s before the restart happens.
##### ./minecraft.sh logs [clean]
Parses logs into several files, grouped into a folder named with the date of the logging.
If the clean option is specified, it will move the older folders into the backup folder.
Again, this command should be issues before a server restart.
##### ./minecraft.sh backup [clean]
Displays a message to the players if the server is online, stops the writing of chunks, create a dated archive and backs up the 
world folder. If the clean option is specified, it will delete the older archives.
##### ./minecraft.sh cartography
Displays a message to the players if the server is online, stops the writing of chunks, initiates c10t's cartography script.
I strongly recommend the MAPS_PATH to be a internet public folder.
##### ./minecraft.sh update
Stops the server if it is online, backs up the old binairies, downloads the last binaries from mincraft.net and restarts 
the server.


### Future updates :
* Bugfixes ?
* Better log parsing, this one is realy primitive
* Anything you could think of.

#### Any advice on how to upgrade this script is very welcome.

