#!/usr/bin/env bash
#
if [ ! -f "$STAGE_SOFTWARE/$OGG_SHIPHOME" ]; then
	echo " ********************************************** "
	echo " $OGGSHIPHOME (goldengate shiphome) not found * "
	echo " ********************************************** "
	exit 1
fi

if [ ! -f "$STAGE_SOFTWARE/$ODB_SHIPHOME1" ]; then
	echo " ********************************************** "
	echo " $DBSHIPHOME1 (database disk 1) not found     * "
	echo " ********************************************** "
	exit 1
fi

if [ ! -f "$STAGE_SOFTWARE/$ODB_SHIPHOME2" ]; then
        echo " ********************************************** "
        echo " $DBSHIPHOME2 (database disk 2) not found     * "
        echo " ********************************************** "
        exit 1
fi

#########SIGINT handler################
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
#########Functions#############
function _stop() {

   echo "Shutting down OGG process ..."
   cd $OGGHOME
   echo 'stop \* '| ggsci
   echo 'stop mgr !'| ggsci
   echo ""
   sleep 30
   echo "Shutting down Oracle Database 12c ..."
   echo shutdown immediate | sqlplus sys/$SYS_PASSWORD as sysdba
   sleep 45
   echo "Shutting down Oracle Database 12c Listener ..."
   su oracle -c "lsnrctl stop"
   sleep 30
   exit 0
}

function _dbstart() {
	echo "Starting Oracle Database 12g "
        echo startup | sqlplus sys/$SYS_PASSWORD as sysdba
        sleep 30
        echo "Starting Oracle Database 12g Listener"
        su oracle -c "lsnrctl start"
        sleep 30
        su oracle -c "lsnrctl status"
}

function _ggstart() {
   echo "Starting Oracle GoldenGate process ..."
   cd $OGGHOME
   echo 'start mgr ' | ggsci
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

##########Oracle Database 12c (12.1.0.2) Installation################
if [ ! -f "/.odbInstalled" ]; then
        echo "Change system shared memory to 5G"
        umount /dev/shm
        mount -t tmpfs shmfs -o size=5G /dev/shm

        echo "Checking shared memory..."
        df -h | grep "Mounted on" && df -h | egrep --color "^.*/dev/shm" || echo "Shared memory is not mounted."

        echo "unzip Oracle shiphomes"
        unzip $STAGE_SOFTWARE/$ODB_SHIPHOME1 -d /install/ && rm -rf $STAGE_SOFTWARE/$ODB_SHIPHOME1
        unzip $STAGE_SOFTWARE/$ODB_SHIPHOME2 -d /install/ && rm -rf $STAGE_SOFTWARE/$ODB_SHIPHOME2

        echo "Database is not installed. Installing..."
        if [ ! -d "/install/database" ]; then
           echo "Installation files not found. Unzip installation files into mounted(/install) folder"
           exit 1
        fi

        echo "Installing Oracle Database 12g (12.1.0.2)"
        GLOBAL_DB_NAME=${HOSTNAME}
        CONN_STR_SID=${HOSTNAME}:$ORACLE_DB_LIST_PORT:$ORACLE_SID
        CONN_STR_SERVICE_NAME=${HOSTNAME}:$ORACLE_DB_LIST_PORT:$ORACLE_SID
        su oracle -c "/install/database/runInstaller -silent -ignorePrereq -waitforcompletion -responseFile $STAGE_SOFTWARE/db_install.rsp"
        $ORACLE_INVENTORY/orainstRoot.sh
        $ORACLE_HOME/root.sh
        echo "Configuring Oracle Database 12g dbca"
        su oracle -c "$ORACLE_HOME/bin/dbca -createDatabase -templateName General_Purpose.dbc -gdbName $GLOBAL_DB_NAME -sid $ORACLE_SID -sysPassword $SYS_PASSWORD -systemPassword $SYS_PASSWORD -emConfiguration LOCAL -dbsnmpPassword $SYS_PASSWORD -datafileJarLocation ${ORACLE_HOME}/assistants/dbca/templates -storageType FS -datafileDestination ${ORACLE_BASE}/oradata -responseFile NO_VALUE -characterset $DB_CHARSET -obfuscatedPasswords false -sampleSchema true -oratabLocation ORATAB -recoveryAreaDestination NO_VALUE -silent"
        echo "Configuring Oracle Database 12g netca"
        su oracle -c "$ORACLE_HOME/bin/netca /orahome $ORACLE_HOME  /orahnam $ORACLE_SID /instype typical /inscomp client,oraclenet,javavm,server,ano /insprtcl tcp /cfg local /authadp NO_VALUE /responseFile ${ORACLE_HOME}/network/install/netca_typ.rsp /silent"
        #su oracle -c "emctl stop dbconsole"
        su oracle -c "$ORACLE_HOME/bin/sqlplus sys/$SYS_PASSWORD as sysdba < $STAGE_SOFTWARE/runSQL.sql"
        touch /.odbInstalled
else
	_dbstart
fi

########Oracle GoldenGate Installation ############

if [ ! -f "/.oggInstalled" ]; then
   unzip $STAGE_SOFTWARE/$OGG_SHIPHOME -d /install/oggcore
   grep oracle.install.responseFileVersion install/oggcore/fbo_ggs_Linux_x64_shiphome/Disk1/response/oggcore.rsp > $STAGE_SOFTWARE/oggcore.rsp
   echo "INSTALL_OPTION=ORA12c"                                  >> $STAGE_SOFTWARE/oggcore.rsp
   echo "SOFTWARE_LOCATION=$OGG_HOME"                            >> $STAGE_SOFTWARE/oggcore.rsp
   echo "START_MANAGER=true"                                     >> $STAGE_SOFTWARE/oggcore.rsp
   echo "MANAGER_PORT=$OGG_PORT"                                 >> $STAGE_SOFTWARE/oggcore.rsp
   echo "DATABASE_LOCATION=$ORACLE_HOME"                         >> $STAGE_SOFTWARE/oggcore.rsp
   echo "INVENTORY_LOCATION=$ORACLE_INVENTORY"                   >> $STAGE_SOFTWARE/oggcore.rsp
   echo "UNIX_GROUP_NAME=oracle"                                 >> $STAGE_SOFTWARE/oggcore.rsp
   su oracle -c "/install/oggcore/fbo_ggs_Linux_x64_shiphome/Disk1/runInstaller -silent -nowait -responsefile $STAGE_SOFTWARE/oggcore.rsp"
   sleep 60
   touch /.oggInstalled
else
   _ggstart
fi

echo " ****************************** "
echo " * container is ready for use * "
echo " ****************************** "

tail -f $OGG_HOME/dirrpt/MGR.rpt &
childPID=$!
wait $childPID
