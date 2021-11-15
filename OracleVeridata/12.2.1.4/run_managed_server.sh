#!/bin/bash
#
#Copyright (c) 2021 Oracle and/or its affiliates.
#
#Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Pass in the managed server name to run and the mapped port
# Author:Arnab Nandi <arnab.x.nandi@oracle.com>

version=$1

set_context() {
   scriptDir="$( cd "$( dirname "$0" )" && pwd )"
   if [ ! -d "${scriptDir}" ]; then
       echo "Unable to determine the working directory for the OracleFMWInfrastructure image"
       echo "Using shell /bin/sh to determine and found ${scriptDir}"
       clean_and_exit
   fi
   echo "Context for docker build is ${scriptDir}"
}

extract_env() {
   env_value=`awk '{print}' $2 | grep ^$1= | cut -d "=" -f2`
   if [ -n "$env_value" ]; then
      env_arg=`echo $1=$env_value`
      echo " env_arg: $env_arg"
      export $env_arg
   fi
}

set_context



extract_env ADMIN_PORT ${scriptDir}/vdt.env
extract_env VERIDATA_PORT ${scriptDir}/vdt.env
extract_env ADMIN_CONTAINER_NAME ${scriptDir}/vdt.env
extract_env VERIDATA_CONTAINER_NAME ${scriptDir}/vdt.env

admin_host() {
   adminhost=${ADMIN_CONTAINER_NAME:-"OggVdtAdminContainer"}
   echo "adminhost= ${adminhost}"
}

managed_name() {
   managedname=${VERIDATA_CONTAINER_NAME:-"OggVdtContainer"}
   echo "managedname= ${managedname}"
}

managed_port() {
   managedport=${VERIDATA_PORT:-7003}
   echo "managedport= ${managedport}"
}

admin_host
managed_name
managed_port

if [ "$version" == "" ]
then
  image_name="oracle/oggvdt:12.2.1.4.0"
  echo "WARNING !! Running $image_name . In case of version please run run_managed_server.sh {version}"
else
  image_name="oracle/oggvdt:12.2.1.4-$version"
fi

docker run -d -p ${managedport}:${managedport} --env-file ${scriptDir}/vdt.env -e VERIDATA_MANAGED_SERVER=true --volumes-from ${adminhost} --name ${managedname}  --network=VdtBridge $image_name startManagedServer.sh
