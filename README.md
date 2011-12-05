Requirements:
==============
- Java runtime environment
- Minecraft Server JAR
- Screen v4.x

Optional:
==============

- c10t (for cartography to work)
- brownan's overviewer script (for overviewer to work)
- Donkey Kong's Biome Extractor (for biomes)
- unzip (for auto updating)

Installation :
==============
- Install the required programs
### Screen and unzip

Try:
     sudo apt-get install screen unzip

Or:
     sudo yum install screen unzip

### c10t

- Download from udoprog's repo:

[https://github.com/udoprog/c10t](https://github.com/udoprog/c10t)

### Minecraft-Overviewer

- Download from brownan's repo:

[http://github.com/brownan/Minecraft-Overviewer](http://github.com/brownan/Minecraft-Overviewer)

### Biome Extractor

- Download from Donkey Kong's post (was tested as of 0.6a):

[http://www.minecraftforum.net/viewtopic.php?f=25&t=80902](http://www.minecraftforum.net/viewtopic.php?f=25&t=80902)

### minecraft.sh

- copy the script into your minecraft server folder.
- allow the script to be executed 
#####     chmod +x minecraft.sh

- check the rights of the script user. Every folder specified in the 
configuration phase has to be available to him.
- edit the script to configure it (see the configuration section)

#### (optional)
- I strongly recommend using crontab to automate some of the process. I 
prefer to perform logs clean + server restart + sync + then all of my mappers at 4AM 
every day. 
- The 'logs' command should always be used BEFORE a restart, as 
the restart wipes the previous logs. I'm running hey0's servermod, which 
allows to have a log history, but that's not the case for everyone.
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

#### Space

This script uses rsync to update an offline folder with the latest world information. As maps become larger, time to completion when running mappers on them increases. Having saving turned off for 15-30 minutes while a new map is being generated isn't good for the users. Saving is now only turned off for the time it takes to sync the folders.

Because of this, your world size is effectively doubled when using this script. Whenever you issue the 'minecraft.sh sync' command, you will be shown the size of the two directories in KB.

#### Overviewer 

If using [Brownan's Overviewer](http://github.com/brownan/Minecraft-Overviewer) to create Google-like maps of your worlds, 
be sure you are using the --cachedir=/path/to/dir to change the location 
of the png files as you will start to take up considerable space since it
defaults to save the files inside of the world folder. This can grow backups
that are only 3mb to 99mb files. If you are not cleaning the logs, this will
start to consume a considerable amount of hard drive space.

#### Multiple Worlds

This script is also setup to work with multiple worlds. Worlds are found by looking for the level.dat file.
If that file is found, the script will consider that an additional world. Keep this in mind when you backup
your world folders as you may end up having operations performed on that folder when you didn't want it to
if you were to just create a copy of the folder in the same root directory 'cp world/ world_backup'. Actions
like sync and cartography will be affected.

Sync will create a copy of the entire world folder(s) into the location you have specified for the offline folder.

Cartography will also run on each found world and will save the images in a folder with the world name in the location
specified for the image output.

Configuration :
===============

There are several variables to set before you can run the script for the first time.
Open minecraft.sh with a text editor, and edit the following lines, at the beginning of the file :

**Main Settings**

    WORLD_NAME="world"
This is the path to the world folder

    OFFLINE_NAME=$WORLD_NAME-offline
This is the name to the offline world folder that sync and all mapper functions use to process the world. This is saved in the same directory as your world folder.

    SCREEN_NAME="minecraft"
This is the name of the screen the server will be run on

    MEMMAX=1024
This is the maximum size of RAM you want to allow the server to use, if you are not sure, keep this and MEMALOC identical.

    DISPLAY_ON_LAUNCH=1
Do you want the screen to be displayed each time the server starts? 1 if yes, 0 if no.

    MC_PATH=/home/minecraft
This is the path to your minecraft folder

    SERVER_OPTIONS=""
This is where you would place any desired flags for running your server.

###### EXAMPLE:
    SERVER_OPTIONS="-XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSIncrementalPacing -XX:ParallelGCThreads=2 -XX:+AggressiveOpts"

**Modifications**

    SERVERMOD=0
If you are running bukkit, this needs to be set to 1 _(better logging and automatic updating of the mod)_

    MODJAR="craftbukkit-0.0.1-SNAPSHOT.jar"
This is the name of the jar file for the server mod you are using. This allows you to use this script for a number of server
mods without having to adjust other parts of the script.

    RUNECRAFT=0
If you want your script to update runecraft automatically too, set this to 1

**Backups**

    BKUP_PATH=$MC_PATH/backup
This is the path to the backup folder. Map backups and old log entries will go there.

    BKUP_DAYS_INCR=3
How long will incremental map backups be kept? _(Only used with the './minecraft.sh backup full' command)_

    BKUP_DAYS_FULL=3
How long will full map backups be kept? _(Only used with the './minecraft.sh backup full' command)_

    BACKUP_FULL_LINK=${BKUP_PATH}/${WORLD_NAME}_full.tgz
Naming convention for full backups.

    BACKUP_INCR_LINK=${BKUP_PATH}/${WORLD_NAME}_incr.tgz
Naming convention for incremental backups.

**Logs**

    LOG_TDIR=/var/www/minecraftLogs
This is the path to the logs folder

    LOGS_DAYS=7
How long will the logs be kept? _(Only used with the './minecraft.sh logs clean' command)_

**Mapping**

    CARTO_PATH=$MC_PATH/carto
This is the path to c10t's cartography script

    MAPS_PATH=/var/www/minecraftMaps
This is the path to the world maps folder

    CARTO_OPTIONS="-q -s"
This contains all of the options you want when running cartography.

    MAP_CHANGES=1
Set this to 1 if you want cartography to also create a 'changes.png' file that will show you what has changed since the last mapper, 0 will turn this feature off.

    BIOME_PATH=/home/minecraft/BiomeExtractor
This is the path to MinecraftBiomeExtractor.jar 

    MCOVERVIEWER_PATH=$MC_PATH/Overviewer/
This is the path to Overviewer (overviewer.py)

    MCOVERVIEWER_MAPS_PATH=/var/www/minecraft/maps/Overview/
This is the location where Overviewer will render

    MCOVERVIEWER_OPTIONS="--rendermodes=lighting,night"
This contains all of the options you want when running Overviewer.

### Detailed Command Usage

##### ./minecraft.sh
Without arguments, the script will resume the server screen. 
(If you want to close the screen without shutting down the server, use 
CTRL+A then press D to detach the screen)
##### ./minecraft.sh status
Tells you if the servers seems to be running, or not.
##### ./minecraft.sh start [force]
Starts the server. If you know your server is not running, but the script believe it is, use the force option.
##### ./minecraft.sh stop [force]
Self explainatory
##### ./minecraft.sh restart [warn]
If the warn option is specified, it will display a warning 30s & 10s before the restart happens.
##### ./minecraft.sh logs [clean]
Parses logs into several files, grouped into a folder named with the date of the logging.
If the clean option is specified, it will move the older folders into the backup folder.
Again, this command should be issues before a server restart.

Note: If you run this command with Hey0, you will see a message that states something like: "Found a log lock : server_##########"
This is not an error and just a notification message. Logs are being generated correctly.

##### ./minecraft.sh backup [full]
Displays a message to the players if the server is online, stops the writing of chunks, create a dated archive and backs up the 
world folder. If the full option is specified, it will delete the older incremental and full archives based on the settings.

#####./minecraft.sh say _message_
If the server is online, this will send the <message> to all users via the console.

Correct: ./minecraft.sh say "This is a public message"

##### ./minecraft.sh tell _user_ _message_
If the server is online, this will send a whisper of <message> to <user>.

Correct: ./minecraft.sh tell test_user "This is a private message"

##### ./minecraft.sh sync [purge]
This updates the offline folder to have the most recent information from the online folder This needs to be ran before you update any maps via 
the commands. The size of both folders will be displayed.

**The purge option will delete the offline folder before a sync is performed. This is useful for when you delete chunks from your online world and need those deletions to be transfered to the offline folder.**

##### ./minecraft.sh cartography [sync]
Displays a message to the players if the server is online, stops the writing of chunks, initiates c10t's cartography script.
I strongly recommend the MAPS_PATH to be an internet public folder.
**The sync option will sync the world before mapping occurs.**
##### ./minecraft.sh overviewer [sync]
Displays a message to the players if the server is online, stops the writing of chunks, initiates Brownan's Overviewer script.
**The sync option will sync the world before mapping occurs.**
I strongly recommend the MCOVERVIER_MAPS_PATH to be an internet public folder as well.
##### ./minecraft.sh biome [sync]
Running the extractor will update any biome information from new chunks.
**The sync option will sync the world before mapping occurs.**
##### ./minecraft.sh update
Stops the server if it is online, backs up the old binaries, downloads the last binaries from minecraft.net and restarts 
the server. If RUNECRAFT=1, then the latest version of Runecraft will be downloaded and injected into the JAR. This is 
the only way to have runecraft installed. If you want Runecraft, but not hMod, then you would set SERVERMOD=0 and RUNECRAFT=1.
You would then run _'./minecraft.sh update'_ to inject Runecraft into just the vanilla server jar (the latest one, of course).


### Future updates :
* Bugfixes ?
* Better log parsing, this one is realy primitive
* Anything you could think of.

#### Any advice on how to upgrade this script is very welcome.

