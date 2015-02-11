#!/bin/sh
#
# Usage:  
#      $ sudo dockNodeManager.sh [-n <container name running admin server>]
#
# Since: October, 2014
# Author: bruno.borges@oracle.com
# Description: script to create a WLS container based on IMAGE_NAME and start NodeManager within it. 
# After NodeManager is started, a script 'add-machine.py' is called that will automatically add the 
# NodeManager as Machine into the domain associated to ADMIN_CONTAINER_NAME
#

SCRIPTS_DIR="$( cd "$( dirname "$0" )" && pwd )"
. $SCRIPTS_DIR/setDockerEnv.sh $*

# CHECK FOR ARGUMENTS
# -n [name] = the name of the admin server container which this NM will automatically plug to. Must exist. Defaults to 'wlsadmin'.
while getopts "i:dhn:" optname
  do
    case "$optname" in
      "i")
        IMAGE_NAME="$OPTARG"
        ;;      
      "d")
        setup_developer
        ;;
      "h")
        echo "Usage: dockNodeManager.sh [-i image] [-n wls_admin_container_name] [-d]"
        echo ""
        echo "   -i image: name of your custom WebLogic Docker image. Default: $IMAGE_NAME."
        echo "   -n name : name of the container with a WebLogic AdminServer orchestrating a domain."
        echo "             Defaults to 'wlsadmin'"
        echo "   -d      : use the developer image to run the container"	
        echo ""
        exit 0
        ;;
      "n")
        ADMIN_CONTAINER_NAME="$OPTARG"
        ;;
      *)
        exit 1
        ;;
    esac
  done

# CHECK IF CONTAINER EXISTS AND IS RUNNING
# Based on https://gist.github.com/ekristen/11254304 (MIT Licensed)
echo -n "Inspecting image name of AdminServer '$ADMIN_CONTAINER_NAME'..."
IMAGE_OF_ADMIN=$(docker inspect -f '{{.Config.Image}}' $ADMIN_CONTAINER_NAME 2> /dev/null)
if [ "$IMAGE_OF_ADMIN" != "$IMAGE_NAME" ]; then
  echo ""
  echo "Admin container '$ADMIN_CONTAINER_NAME' is from a different image: '$IMAGE_OF_ADMIN', while you want to use image '$IMAGE_NAME'."
  exit $?
fi

echo "Inspecting running state of AdminServer '$ADMIN_CONTAINER_NAME'..."
ADMIN_CONTAINER_RUNNING=$(docker inspect --format="{{ .State.Running }}" $ADMIN_CONTAINER_NAME 2> /dev/null)

if [ $? -eq 1 ]; then
  echo ""
  echo "Admin container '$ADMIN_CONTAINER_NAME' with WLS Admin Server running does not exist. Create one first calling 'dockWebLogic.sh -n $ADMIN_CONTAINER_NAME'"
  exit $? 
fi
 
if [ "$ADMIN_CONTAINER_RUNNING" = "false" ]; then
  echo ""
  echo "Admin container '$ADMIN_CONTAINER_NAME' is not running. Unpause or start it"
  exit $?
fi

echo "[OK]!"

echo -n "Inspecting ghost state of AdminServer..." 
GHOST_STATUS=$(docker inspect --format="{{ .State.Ghost }}" $ADMIN_CONTAINER_NAME)
 
if [ "$GHOST_STATUS" = "true" ]; then
  echo ""
  echo "Admin container '$ADMIN_CONTAINER_NAME' has been ghosted. Destroy it and create again."
  exit $?
fi 

if [ $? -eq 1 ]; then
  exit $?
fi;

echo "[OK!]"

# RUN DOCKER
echo -n "Creating NodeManager container..."
docker run -d \
 --name ${NM_CONTAINER_NAME} \
 -e DOCKER_CONTAINER_NAME=${NM_CONTAINER_NAME} \
 --link $ADMIN_CONTAINER_NAME:wlsadmin $IMAGE_NAME \
 /u01/oracle/createMachine.sh > /dev/null 2>&1

echo "[OK!]"

if [ $? -eq 1 ]; then
  echo ""
  exit $?
fi;

echo -n "Inspecting IP address of newly created NodeManger container with name '$NM_CONTAINER_NAME'..."
NMIP=$(docker inspect --format='{{.NetworkSettings.IPAddress}}' $NM_CONTAINER_NAME)
echo "[OK!]"
echo "===================="
echo "New NodeManager [$NM_CONTAINER_NAME] started on IP Address: $NMIP."
echo "Hopefully this Machine was automatically added to 'base_domain' in the [$ADMIN_CONTAINER_NAME] admin server."
echo "If not, go to Admin Console and try to add it manually with this IP address."
