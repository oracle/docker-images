#!/bin/bash
#
#Copyright (c) 2017 CERN
#

# ORDS configuration
#------------------
# Set config.dir value in WEB-INF/web.xml deployment descriptor of the ords.war
java -jar $ORDS_HOME/ords.war configdir $ORDS_HOME/conf

# Add the database attributes to the ords_params.properties
echo "db.hostname=$DB_HOSTNAME" >> $ORDS_HOME/params/ords_params.properties
echo "db.port=$DB_PORT" >> $ORDS_HOME/params/ords_params.properties
echo "db.servicename=$DB_SERVICENAME" >> $ORDS_HOME/params/ords_params.properties
echo "user.public.password=$USER_PUBLIC_PASSWORD" >> $ORDS_HOME/params/ords_params.properties
echo "sys.user=$SYS_USER" >> $ORDS_HOME/params/ords_params.properties

# ORDS installation
#------------------
# It will create the ORDS_METADATA and ORDS_PUBLIC_USER in the ORDS db
java -jar $ORDS_HOME/ords.war install simple

# ORDS deployment on WebLogic (AdminServer)
#------------------------------------------
# Move ords.war to the autodeploy folder
mv $ORDS_HOME/ords.war $DOMAIN_HOME/autodeploy/

# Start weblogic. It should pick up the ords.war from autodeploy folder and deploy it on the AdminServer under the context /ords
$DOMAIN_HOME/startWebLogic.sh
