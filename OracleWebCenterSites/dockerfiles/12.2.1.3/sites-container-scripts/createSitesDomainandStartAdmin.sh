#!/bin/bash
#
# Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Description: This script is used to Create Sites Domain, Execute RCU, Configwizard, and silent SitesConfig process. It will start and stop managed server during SitesConfig process, and finally restart Admin server.
#

########### SIGINT handler ############
function _int() {
   echo "Stopping container."
   echo "SIGINT received, shutting down Admin Server!"
   $DOMAIN_HOME/bin/stopWebLogic.sh
   exit;
}

########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down Admin Server!"
   $DOMAIN_HOME/bin/stopWebLogic.sh
   exit;
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down the server!"
   kill -9 $childPID
}

#######Random Password Generation########
function rand_pwd(){
    while true; do
         s=$(cat /dev/urandom | tr -dc "A-Za-z0-9" | fold -w 8 | head -n 1)
         if [[ ${#s} -ge 8 && "$s" == *[A-Z]* && "$s" == *[a-z]* && "$s" == *[0-9]*  ]]
         then
             break
         else
             echo "Password does not Match the criteria, re-generating..." >&2
         fi
    done
    echo "${s}" 
}

INSTALL_START=$(date '+%s')

# Set SIGINT handler
trap _int SIGINT

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

#Check on required parameters
PARAMS=true

if [ -z $DOCKER_HOST ]; then
	echo "DOCKER_HOST not set."
	PARAMS=false
fi

if [ -z $DB_CONNECTSTRING ]; then
	echo "DB_CONNECTSTRING not set."
	PARAMS=false
fi

if [ -z $DB_USER ]; then
	echo "DB_USER not set."
	PARAMS=false
fi

if [ -z $DB_PASSWORD ]; then
	echo "DB_PASSWORD not set."
	PARAMS=false
fi

if [ -z $RCU_PREFIX ]; then
	echo "RCU_PREFIX not set."
	PARAMS=false
fi

if [ $PARAMS == "false" ]; then
	echo "All above required parameters not set in wcsitesadminserver.env.list"
    exit;    
fi

if [ -z ${DOMAIN_NAME} ]
then
    DOMAIN_NAME=base_domain
    echo ""
    echo " Setting DOMAIN_NAME to base_domain"
    echo ""
fi

if [ -z ${SITES_SERVER_NAME} ]
then
    SITES_SERVER_NAME=wcsites_server1
    echo ""
    echo " Setting SITES_SERVER_NAME to wcsites_server1"
    echo ""
fi

if [ -z ${ADMIN_USERNAME} ]
then
    ADMIN_USERNAME=weblogic
    echo ""
    echo " Setting ADMIN_USERNAME to weblogic"
    echo ""
fi

if [ -z ${SITES_ADMIN_USERNAME} ]
then
    SITES_ADMIN_USERNAME=ContentServer
    echo ""
    echo " Setting SITES_ADMIN_USERNAME to ContentServer"
    echo ""
fi

if [ -z ${SITES_APP_USERNAME} ]
then
    SITES_APP_USERNAME=fwadmin
    echo ""
    echo " Setting SITES_APP_USERNAME to fwadmin"
    echo ""
fi

if [ -z ${SITES_SS_USERNAME} ]
then
    SITES_SS_USERNAME=SatelliteServer
    echo ""
    echo " Setting SITES_SS_USERNAME to SatelliteServer"
    echo ""
fi

if [ -z ${SAMPLES} ]
then
    SAMPLES=false
    echo ""
    echo " Setting samples to false"
    echo ""
fi

if [ -z ${ADMIN_PASSWORD} ]
then
    # Auto generate Oracle WebLogic Server admin password
    ADMIN_PASSWORD=$(rand_pwd)
    echo ""
    echo "    Oracle WebLogic Server Password Auto Generated :"
    echo ""
    echo "    ----> Username: $ADMIN_USERNAME ----> Password: $ADMIN_PASSWORD"
    echo ""
fi;

if [ -z ${DB_SCHEMA_PASSWORD} ]
then
    # Auto generate Oracle Database Schema password
    temp_pwd=$(rand_pwd)
    #Password should not start with a number for database
    f_str=`echo $temp_pwd|cut -c1|tr [0-9] [A-Z]`
    s_str=`echo $temp_pwd|cut -c2-`
    DB_SCHEMA_PASSWORD=${f_str}${s_str}
    echo ""
    echo "    Database Schema password Auto Generated :"
    echo ""
    echo "    ----> Database schema password: $DB_SCHEMA_PASSWORD"
    echo ""
fi

if [ -z ${SITES_ADMIN_PASSWORD} ]
then
    # Auto generate Oracle WebCenter Sites Administrator password
    SITES_ADMIN_PASSWORD=$(rand_pwd)
    echo ""
    echo "    Oracle WebCenter Sites Administrator Password Auto Generated :"
    echo ""
    echo "    ----> Username: $SITES_ADMIN_USERNAME ----> Password: $SITES_ADMIN_PASSWORD"
    echo ""
fi;

if [ -z ${SITES_APP_PASSWORD} ]
then
    # Auto generate Oracle WebCenter Sites Application password
    SITES_APP_PASSWORD=$(rand_pwd)
    echo ""
    echo "    Oracle WebCenter Sites Application Password Auto Generated :"
    echo ""
    echo "    ----> Username: $SITES_APP_USERNAME ----> Password: $SITES_APP_PASSWORD"
    echo ""
fi;

if [ -z ${SITES_SS_PASSWORD} ]
then
    # Auto generate Oracle WebCenter Sites SatelliteServer password
    SITES_SS_PASSWORD=$(rand_pwd)
    echo ""
    echo "    Oracle WebCenter Sites SatelliteServer Password Auto Generated :"
    echo ""
    echo "    ----> Username: $SITES_SS_USERNAME ----> Password: $SITES_SS_PASSWORD"
    echo ""
fi;

# These values can be parameterized later on. Hardcoding for now.
export DOCKER_HOST=$DOCKER_HOST

#Database Parameters
export DB_USER=$DB_USER
export DB_PASSWORD=$DB_PASSWORD
export DB_CONNECTSTRING=$DB_CONNECTSTRING

#Installer Parameters
export RCU_PREFIX=$RCU_PREFIX
export SAMPLES=$SAMPLES
export DOMAIN_NAME=$DOMAIN_NAME
export SITES_SERVER_NAME=$SITES_SERVER_NAME
export ADMIN_USERNAME=$ADMIN_USERNAME
export ADMIN_PORT=7001
export WCSITES_MANAGED_PORT=7002
export ADMIN_SSL_PORT=9001
export WCSITES_SSL_PORT=9002
ORACLE_HOME=/u01/oracle
WORK_DIR=/u01/oracle/user_projects/wcs-wls-docker-install/work
JAVA_PATH=/usr/java/default/bin/java

#Hostname Parameters
export WCSITES_ADMIN_HOSTNAME=$(sed -r 's/\./\\\./g' <<< $(hostname -I))

#dos2unix $SITES_CONTAINER_SCRIPTS/*.*

#--------------------------------------------------------------------------------------------
cd /u01/wcs-wls-docker-install
#find bootstrap.properties -type f -exec dos2unix {} {} \;

sed -i 's,^\(script.rcu.prefix=\).*,\1'$RCU_PREFIX',' bootstrap.properties
sed -i 's,^\(script.java.path=\).*,\1'$JAVA_PATH',' bootstrap.properties
sed -i 's,^\(script.oracle.wcsites.hostname=\).*,\1'$WCSITES_ADMIN_HOSTNAME',' bootstrap.properties
sed -i 's,^\(script.oracle.wcsites.portnumber=\).*,\1'$WCSITES_MANAGED_PORT',' bootstrap.properties
sed -i 's,^\(script.db.user=\).*,\1'$DB_USER',' bootstrap.properties
sed -i 's,^\(script.db.password=\).*,\1'$DB_PASSWORD',' bootstrap.properties
sed -i 's,^\(script.db.schema.password=\).*,\1'$DB_SCHEMA_PASSWORD',' bootstrap.properties
sed -i 's,^\(script.db.connectstring=\).*,\1'$DB_CONNECTSTRING',' bootstrap.properties
sed -i 's,^\(script.oracle.home=\).*,\1'$ORACLE_HOME',' bootstrap.properties
sed -i 's,^\(script.work.dir=\).*,\1'$WORK_DIR',' bootstrap.properties
sed -i 's,^\(script.oracle.wcsites.examples.avisports=\).*,\1'$SAMPLES',' bootstrap.properties
sed -i 's,^\(script.oracle.wcsites.examples.fsii=\).*,\1'$SAMPLES',' bootstrap.properties
sed -i 's,^\(script.oracle.wcsites.examples.Samples=\).*,\1'$SAMPLES',' bootstrap.properties
sed -i 's,^\(script.oracle.wcsites.examples.blogs=\).*,\1'$SAMPLES',' bootstrap.properties
sed -i 's,^\(script.wcsites.binaries.install.with.examples=\).*,\1'$SAMPLES',' bootstrap.properties
sed -i 's,^\(script.oracle.domain=\).*,\1'$DOMAIN_NAME',' bootstrap.properties
sed -i 's,^\(script.server.name=\).*,\1'$SITES_SERVER_NAME',' bootstrap.properties
sed -i 's,^\(script.admin.server.username=\).*,\1'$ADMIN_USERNAME',' bootstrap.properties
sed -i 's,^\(script.admin.server.password=\).*,\1'$ADMIN_PASSWORD',' bootstrap.properties
sed -i 's,^\(script.admin.server.port=\).*,\1'$ADMIN_PORT',' bootstrap.properties
sed -i 's,^\(script.admin.server.ssl.port=\).*,\1'$ADMIN_SSL_PORT',' bootstrap.properties
sed -i 's,^\(script.sites.server.ssl.port=\).*,\1'$WCSITES_SSL_PORT',' bootstrap.properties
sed -i 's,^\(script.oracle.wcsites.system.admin.user=\).*,\1'$SITES_ADMIN_USERNAME',' bootstrap.properties
sed -i 's,^\(script.oracle.wcsites.system.admin.password=\).*,\1'$SITES_ADMIN_PASSWORD',' bootstrap.properties
sed -i 's,^\(script.oracle.wcsites.app.user=\).*,\1'$SITES_APP_USERNAME',' bootstrap.properties
sed -i 's,^\(script.oracle.wcsites.app.password=\).*,\1'$SITES_APP_PASSWORD',' bootstrap.properties
sed -i 's,^\(script.oracle.wcsites.satellite.user=\).*,\1'$SITES_SS_USERNAME',' bootstrap.properties
sed -i 's,^\(script.oracle.wcsites.satellite.password=\).*,\1'$SITES_SS_PASSWORD',' bootstrap.properties

#--------------------------------------------------------------------------------------------
#RCU + ConfigWizard + Sites Configuration
#Groovy files are responsible for exexuting RCU + ConfigWizard + Sites Configuration for Sites.
#Source files for the same are located at ./OracleWebCenterSites/dockerfiles/12.2.1.3/wcs-wls-docker-install/src/
java -jar wcs-wls-docker-install.jar

#--------------------------------------------------------------------------------------------

if [ -e $WORK_DIR/WCSites_Config_Setup.suc ] 
then
	echo ""	
	echo "Sites installation is successfull!!!"	
else
	echo ""	
	echo "Sites installation has failed. Please check Admin Container log for details"
	exit
fi
	
#
# Export Domain Home/Root
#=========================
export DOMAIN_NAME=$DOMAIN_NAME
export DOMAIN_ROOT="/u01/oracle/user_projects/domains"
export DOMAIN_HOME="${DOMAIN_ROOT}/${DOMAIN_NAME}"

#
# Creating domain env file
#=========================
echo "WCSITES_ADMIN_HOSTNAME="$WCSITES_ADMIN_HOSTNAME>> $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/param.properties
echo "WCSITES_ADMIN_PORT="$ADMIN_PORT>> $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/param.properties
echo "WCSITES_MANAGED_HOSTNAME="$WCSITES_ADMIN_HOSTNAME>> $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/param.properties
echo "WCSITES_MANAGED_PORT="$WCSITES_MANAGED_PORT>> $DOMAIN_HOME/servers/${SITES_SERVER_NAME}/logs/param.properties

#--------------------------------------------------------------------------------------------
echo "Replacement started."

sh $SITES_CONTAINER_SCRIPTS/replaceSitesTokens.sh

rm $SITES_CONTAINER_SCRIPTS/replaceSitesTokens.sh

echo "Replacement done successfully."
#--------------------------------------------------------------------------------------------

echo ""
echo ""
echo "Notedown Sites, WebLogic Server and Database Schema passwords:"
echo ""
echo "    ----> Oracle Database Schema Credential:													Password: $DB_SCHEMA_PASSWORD"
echo "    ----> Oracle WebLogic Server Credential:					Username: $ADMIN_USERNAME		Password: $ADMIN_PASSWORD"
echo "    ----> Oracle WebCenter Sites Administrator Credential:	Username: $SITES_ADMIN_USERNAME	Password: $SITES_ADMIN_PASSWORD"
echo "    ----> Oracle WebCenter Sites Application Credential: 		Username: $SITES_APP_USERNAME	Password: $SITES_APP_PASSWORD"
echo "    ----> Oracle WebCenter Sites SatelliteServer Credential: 	Username: $SITES_SS_USERNAME 	Password: $SITES_SS_PASSWORD"
echo ""
echo "Admin Server started, ready to start Managed Servers"
echo "    ----> $SITES_CONTAINER_SCRIPTS/startSitesServer.sh $SITES_SERVER_NAME"
echo ""

echo "Start Sites Managed Server once Admin Server is started."

# Now we start the Admin server in this container... 
sh $SITES_CONTAINER_SCRIPTS/startAdminServer.sh

INSTALL_END=$(date '+%s')
INSTALL_ELAPSED=`expr $INSTALL_END - $INSTALL_START`

echo "Sites Installation completed in $INSTALL_ELAPSED seconds."
echo "---------------------------------------------------------"
echo ""

# Tail Admin Server logs... 
touch ${DOMAIN_HOME}/servers/AdminServer/logs/AdminServer.log
tail -f ${DOMAIN_HOME}/servers/AdminServer/logs/AdminServer.log &

childPID=$!
wait $childPID