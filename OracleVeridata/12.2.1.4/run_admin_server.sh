#! /bin/bash
#
#Copyright (c) 2021 Oracle and/or its affiliates.
#
#Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
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

extract_env WEBLOGIC_PORT ${scriptDir}/vdt.env
extract_env DOMAIN_HOST_VOLUME ${scriptDir}/vdt.env
extract_env ADMIN_CONTAINER_NAME ${scriptDir}/vdt.env
extract_env ADMIN_CONTAINER_NAME ${scriptDir}/vdt.env
extract_env ADMIN_CONTAINER_NAME ${scriptDir}/vdt.env
#extract_env DOMAIN_HOST_VOLUME ${scriptDir}/vdt.env

# HOST volume where the domain home will be persisted
domain_host_volume() {
   domainhostvol=${DOMAIN_HOST_VOLUME}
   echo "Domain Host Volume0: $domainhostvol"
   domainhostvol=${DOMAIN_HOST_VOLUME:-"/home/oracle/oggvdt/domain_home"}
   echo "Domain Host Volume: $domainhostvol"
}

admin_host() {
   adminhost=${ADMIN_CONTAINER_NAME:-"OggVdtAdminContainer"}
   echo "Admin Host is: $adminhost"
}

admin_port() {
   adminport=${WEBLOGIC_PORT:-7001}
   echo "Admin Host is: $adminport"
}



admin_host

domain_host_volume

admin_port

if [ "$version" == "" ]
then
  image_name="oracle/oggvdt:12.2.1.4.0"
  echo "WARNING !! Running $image_name . In case of version please run run_admin_server.sh {version}"
else
  image_name="oracle/oggvdt:12.2.1.4-$version"
fi

echo " docker run -d -p ${adminport}:${adminport}  --name ${adminhost} --network=VdtBridge  --env-file ${scriptDir}/vdt.env -e VERIDATA_ADMIN_SERVER=true -v ${domainhostvol}:/u01/oracle/user_projects $image_name createOrStartVdtDomain.sh"

docker run -d -p ${adminport}:${adminport}  --name ${adminhost} --network=VdtBridge  --env-file ${scriptDir}/vdt.env -e VERIDATA_ADMIN_SERVER=true -v ${domainhostvol}:/u01/oracle/user_projects $image_name createOrStartVdtDomain.sh

