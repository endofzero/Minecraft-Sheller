#       Configuration
echo "Alternate Config file in use"
# Main
MC_PATH=/home/minecraft
SERVER_PATH=""
ONLINE_PATH=$MC_PATH/$SERVER_PATH
OFFLINE_PATH=$MC_PATH/offline
USE_RAMDISK=0
RAMDISK_PATH=/dev/shm/
SCREEN_NAME="minecraft"
MEMMAX=1536
DISPLAY_ON_LAUNCH=0
SERVER_OPTIONS="-XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSIncrementalPacing -XX:ParallelGCThreads=2 -XX:+AggressiveOpts"

# Modifications
SERVERMOD=1
MODJAR="craftbukkit-0.0.1-SNAPSHOT.jar"
RUNECRAFT=1
MCMYADMIN=0


# Backups
BKUP_PATH=$MC_PATH/backup
BKUP_DAYS_INCR=2
BKUP_DAYS_FULL=5

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

#       End of configuration

