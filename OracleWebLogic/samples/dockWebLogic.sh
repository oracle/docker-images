#!/bin/sh
#
# Usage:  
#    -a [port]: attach AdminServer port to host. If -a is present, will attach. Defaults to 7001.
#    -n [name]: give a different name for the container. default: wlsadmin
#    -d       : use the developer image to run the container
#  $ sudo sh dockWebLogic.sh -n [container name running admin server]
#
# Since: October, 2014
# Author: bruno.borges@oracle.com
# Description: script to create a container with WLS Admin Server
# based on IMAGE_NAME within it.
#

SCRIPTS_DIR="$( cd "$( dirname "$0" )" && pwd )"
. $SCRIPTS_DIR/setDockerEnv.sh $*

# CHECK AND READ ARGUMENTS
while getopts "ai:n:p:h" optname
  do
    case "$optname" in
      "h")
        echo "Starts the WebLogic AdminServer within a Docker container."
        echo "Usage: dockWebLogic.sh [-i image] [-a [-p port]] [-n mywlsadmin]"
        echo ""
        echo "   -a      : attach AdminServer port to host. If -a is present, will attach. Change default (7001) with -p port"
        echo "   -p port : which port on host to attach AdminServer. Default: 7001"
        echo "   -i image: name of your custom WebLogic Docker image."
        echo "   -n name : give a different name for the container. Default: wlsadmin"
        echo ""
        exit 0
        ;;
      "a")
        MUST_ATTACH=true
        ;;
      "p")
        ATTACH_ADMIN_TO="$OPTARG"
        ;;
      "n")
        ADMIN_CONTAINER_NAME="$OPTARG"
        ;;
      "i")
        IMAGE_NAME="$OPTARG"
        ;;
      "d")
        setup_developer
        ;;
      *)
        exit 1
        ;;
    esac
  done

if [ $MUST_ATTACH ]; then
    ATTACH_DEFAULT_PORT="-p $ATTACH_ADMIN_TO:7001"
fi

# RUN THE DOCKER COMMAND
docker run \
 -d $ATTACH_DEFAULT_PORT \
 --name $ADMIN_CONTAINER_NAME $IMAGE_NAME \
 /u01/oracle/weblogic/user_projects/domains/base_domain/startWebLogic.sh

if [ $? -eq 1 ]; then
  exit $?
fi;

# EXTRACT THE IP ADDRESS
if [ -n "${ATTACH_DEFAULT_PORT}" ]
then
  WLS_ADMIN_IP=localhost
else
  WLS_ADMIN_IP=$(docker inspect --format='{{.NetworkSettings.IPAddress}}' $ADMIN_CONTAINER_NAME)
fi

# REPORT IF DOCKER SUCCEEDED
if [ "$?" = 0 ]; then
  echo "WebLogic starting... "
  sleep 10
  echo "Open WebLogic Console at http://${WLS_ADMIN_IP}:${ATTACH_ADMIN_TO}/console"
else
  echo "There was an error trying to create a container"
  exit $?
fi
