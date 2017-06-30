#!/usr/bin/env bash

if [ ! -f "$STAGE_SOFTWARE/$OGG_SHIPHOME" ]; then
   echo " ************************************************* "
   echo " * $OGGSHIPHOME (goldengate shiphome) not found  * "
   echo " ************************************************* "
   exit 1
fi
########### SIGINT handler ############
function _int() {
   echo "Stopping container."
   echo "SIGINT received, shutting down Admin Server!"
   _stop
   exit;
}
########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down Admin Server!"
   _stop 
   exit;
}
########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down the server!"
   _stop 
   kill -9 $childPID
}
########################################
function _stop() {
   echo "Shutting down OGG process ..."
   cd $OGG_HOME
   echo 'stop \* '| ggsci
   echo 'stop mgr !'| ggsci
   echo ""
   exit 0
}
function _start() {
   echo "Starting Up OGG process ..."
   cd $OGG_HOME
   echo 'start mgr '| ggsci
   echo 'start \* '| ggsci
   echo ""
   sleep 60
}
########################################
# Set SIGINT handler
trap _int SIGINT
# Set SIGTERM handler
trap _term SIGTERM
# Set SIGKILL handler
trap _kill SIGKILL
########################################

if [ ! -f "/.oggInstalled" ]; then
   unzip $STAGE_SOFTWARE/$OGG_SHIPHOME -d $OGG_HOME
   cd $OGG_HOME
   tar -xvf *.tar
   echo "create subdirs" | ggsci
   echo ""
   echo "port $OGG_PORT " > $OGG_HOME/dirprm/MGR.prm
   echo "start mgr" | ggsci
   echo ""
   sleep 60
   touch /.oggInstalled
else
   _start
fi

        echo " ****************************** "
        echo " * container is ready for use * "
        echo " ****************************** "

tail -f $OGG_HOME/dirrpt/MGR.rpt &
childPID=$!
wait $childPID
