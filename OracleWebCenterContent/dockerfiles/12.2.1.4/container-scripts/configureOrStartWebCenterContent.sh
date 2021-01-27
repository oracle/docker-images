#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#

function validate_parameter {
  name=$1
  value=$2
  if [ -z $value ]
  then
    echo "ERROR: Please set '$name' in configmap[webcenter.env.list file]."
    echo ""       
    exit 1
  fi
}

# validate HOSTNAME
validate_parameter "HOSTNAME" $HOSTNAME
validate_parameter "UCM_PORT" $UCM_PORT
validate_parameter "IBR_PORT" $IBR_PORT
validate_parameter "UCM_HOST_PORT" $UCM_HOST_PORT
validate_parameter "IBR_HOST_PORT" $IBR_HOST_PORT
validate_parameter "UCM_INTRADOC_PORT" $UCM_INTRADOC_PORT
validate_parameter "IBR_INTRADOC_PORT" $IBR_INTRADOC_PORT

export vol_name=u01
export server=UCM_server1
export UCM_PORT=$UCM_PORT
export IBR_PORT=$IBR_PORT
export UCM_INTRADOC_PORT=$UCM_INTRADOC_PORT
export IBR_INTRADOC_PORT=$IBR_INTRADOC_PORT
export UCM_HOST_PORT=$UCM_HOST_PORT
export IBR_HOST_PORT=$IBR_HOST_PORT

# get the hostname FQDN
export hostname=$HOSTNAME

echo "Environment variables"
echo "====================="
echo ""
echo "HOSTNAME=${hostname}"
echo "vol_name=${vol_name}"
echo "UCM_PORT=${UCM_PORT}"
echo "IBR_PORT=${IBR_PORT}"
echo "UCM_HOST_PORT=${UCM_HOST_PORT}"
echo "IBR_HOST_PORT=${IBR_HOST_PORT}"
echo "UCM_INTRADOC_PORT=${UCM_INTRADOC_PORT}"
echo "IBR_INTRADOC_PORT=${IBR_INTRADOC_PORT}"
echo ""
echo ""

if [ -z ${KEEP_CONTAINER_ALIVE} ]
then
   # by default we always keep this flag ON
   export KEEP_CONTAINER_ALIVE="true"
fi

export KEEP_CONTAINER_ALIVE=$KEEP_CONTAINER_ALIVE
export CONTAINERCONFIG_DIR_NAME="container-data"
export CONTAINERCONFIG_DIR="/$vol_name/oracle/user_projects/$CONTAINERCONFIG_DIR_NAME"
export CONTAINERCONFIG_LOG_DIR="$CONTAINERCONFIG_DIR/logs"

# remove the space from hostname
hostname=`echo $hostname | sed  's/^[[:space:]]*//'`

# find & replace '.' from hostname
hostalias=`echo $hostname | sed  's/[.]//g'`
truncatedhostname=${hostalias}


if [ ${#truncatedhostname} -gt "20" ]
then
    truncatedhostname=${truncatedhostname:0:10}
fi

if [ -f /$vol_name/oracle//oracle_common/lib/ons.jar ]
then
    rm /$vol_name/oracle//oracle_common/lib/ons.jar
fi

if [ -f /$vol_name/oracle/oracle_common/modules/oracle.jdbc/simplefan.jar ]
then
    rm /$vol_name/oracle/oracle_common/modules/oracle.jdbc/simplefan.jar
fi


#start UCM Server
sh /u01/oracle/container-scripts/startManagedServer.sh $server

#Configure CS after first start up
sh /u01/oracle/container-scripts/stopManagedServer.sh $server

# Replace below static values with  dynamic host value

if [ "$UCM_HOST_PORT" -eq  "$UCM_PORT" ]
then
    sed -i "s/@UCM_PORT@/$UCM_PORT/g" /$vol_name/oracle/container-scripts/autoinstall.cfg.cs
    sed -i "s/@UCM_PORT@/$UCM_PORT/g" /$vol_name/oracle/container-scripts/ucm.properties
else
   sed -i "s/@UCM_PORT@/$UCM_HOST_PORT/g" /$vol_name/oracle/container-scripts/autoinstall.cfg.cs
   sed -i "s/@UCM_PORT@/$UCM_HOST_PORT/g" /$vol_name/oracle/container-scripts/ucm.properties
fi

sed -i "s/@INSTALL_HOST_FQDN@/$hostname/g" /$vol_name/oracle/container-scripts/autoinstall.cfg.cs
sed -i "s/@INSTALL_HOST_NAME@/$hostalias/g" /$vol_name/oracle/container-scripts/autoinstall.cfg.cs
sed -i "s/@HOST_NAME_PREFIX@/$truncatedhostname/g" /$vol_name/oracle/container-scripts/autoinstall.cfg.cs
sed -i "s/@UCM_INTRADOC_PORT@/$UCM_INTRADOC_PORT/g" /$vol_name/oracle/container-scripts/autoinstall.cfg.cs
sed -i "s/@UCM_INTRADOC_PORT@/$UCM_INTRADOC_PORT/g" /$vol_name/oracle/container-scripts/ucm.properties

cp -v /$vol_name/oracle/container-scripts/autoinstall.cfg.cs /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/ucm/cs/bin/autoinstall.cfg

chown oracle:oracle -R /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/ucm/cs/bin/autoinstall.cfg
chmod a+xr /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/ucm/cs/bin/autoinstall.cfg

sh /u01/oracle/container-scripts/startManagedServer.sh $server

export server1=IBR_server1

#start IBR Server
sh /u01/oracle/container-scripts/startManagedServer.sh $server1

#Configure IBR after first start up
sh /u01/oracle/container-scripts/stopManagedServer.sh $server1

# Replace below static values with  dynamic host value

if [ "$IBR_HOST_PORT" -eq  "$IBR_PORT" ]
then
   sed -i "s/@IBR_PORT@/$IBR_PORT/g" /$vol_name/oracle/container-scripts/autoinstall.cfg.ibr 
   sed -i "s/@IBR_PORT@/$IBR_PORT/g" /$vol_name/oracle/container-scripts/ucm.properties
else
   sed -i "s/@IBR_PORT@/$IBR_HOST_PORT/g" /$vol_name/oracle/container-scripts/autoinstall.cfg.ibr
   sed -i "s/@IBR_PORT@/$IBR_HOST_PORT/g" /$vol_name/oracle/container-scripts/ucm.properties
   
fi

sed -i "s/@INSTALL_HOST_FQDN@/$hostname/g" /$vol_name/oracle/container-scripts/autoinstall.cfg.ibr
sed -i "s/@INSTALL_HOST_NAME@/$hostalias/g" /$vol_name/oracle/container-scripts/autoinstall.cfg.ibr
sed -i "s/@IBR_INTRADOC_PORT@/$IBR_INTRADOC_PORT/g" /$vol_name/oracle/container-scripts/autoinstall.cfg.ibr
sed -i "s/@IBR_INTRADOC_PORT@/$IBR_INTRADOC_PORT/g" /$vol_name/oracle/container-scripts/ucm.properties

cp -v /$vol_name/oracle/container-scripts/autoinstall.cfg.ibr /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/ucm/ibr/bin/autoinstall.cfg

chown oracle:oracle -R /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/ucm/ibr/bin/autoinstall.cfg
chmod a+xr /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/ucm/ibr/bin/autoinstall.cfg

sh /u01/oracle/container-scripts/startManagedServer.sh $server1

export servers=UCMandIBR
echo ""
echo ""
if [ "$KEEP_CONTAINER_ALIVE" == "true" ]
then
  # This keeps the container running and alive
  sh /$vol_name/oracle/container-scripts/keepContainerAlive.sh $CONTAINERCONFIG_LOG_DIR $hostname $servers
fi

