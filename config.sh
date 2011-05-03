#       Configuration
echo "Alternate Config file in use"
# Main
WORLD_NAME="world"
OFFLINE_NAME=$WORLD_NAME-offline
MC_PATH=/home/minecraft
SCREEN_NAME="minecraft"
MEMMAX=1536
DISPLAY_ON_LAUNCH=0
SERVER_OPTIONS="-XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSIncrementalPacing -XX:ParallelGCThreads=2 -XX:+AggressiveOpts"

# Modifications
SERVERMOD=1
MODJAR="craftbukkit-0.0.1-SNAPSHOT.jar"
RUNECRAFT=1


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

#       End of configuration

