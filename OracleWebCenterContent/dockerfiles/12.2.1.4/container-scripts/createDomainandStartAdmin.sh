#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#

export vol_name=u01

########### SIGINT handler ############
function _int() {
   echo "Stopping container.."
   echo "SIGINT received, shutting down servers!"
   echo ""
   echo "Stopping Node Manager.."
   /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/stopNodeManager.sh
   echo "Stopping Admin Server.."
   /$vol_name/oracle/container-scripts/stopAdmin.sh
   exit;
EOF
   lsnrctl stop
}

########### SIGTERM handler ############
function _term() {
   echo "Stopping container.."
   echo "SIGTERM received, shutting down Servers!"
   echo ""
   echo "Stopping Node Manager.."
   /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/stopNodeManager.sh
   echo "Stopping Admin Server.."
   /$vol_name/oracle/container-scripts/stopAdmin.sh
   exit;
EOF
   lsnrctl stop
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down Servers!"
   echo ""
   echo "Stopping Node Manager.."
   /$vol_name/oracle/user_projects/domains/$DOMAIN_NAME/bin/stopNodeManager.sh
   echo "Stopping Admin Server.."
   /$vol_name/oracle/container-scripts/stopAdmin.sh
   exit;
EOF
   lsnrctl stop
}



# Set SIGINT handler
trap _int SIGINT

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

export CONTAINERCONFIG_DIR_NAME="container-data"
export CONTAINERCONFIG_DIR="/$vol_name/oracle/user_projects/$CONTAINERCONFIG_DIR_NAME"
export CONTAINERCONFIG_LOG_DIR="$CONTAINERCONFIG_DIR/logs"
export CONTAINERCONFIG_DOMAIN_DIR="/$vol_name/oracle/user_projects/domains"

echo ""
echo "========================================================="
echo "            WebCenter Content Docker Container            "
echo "                      Admin Server                       "
echo "                       12.2.1.4.0                        "
echo "========================================================="
echo ""
echo ""

# Persistence volume location mapped to this location will need permission fixup
if [ -d $CONTAINERCONFIG_DIR ]; then
    chown -R oracle:root $CONTAINERCONFIG_DOMAIN_DIR
    chown -R oracle:root $CONTAINERCONFIG_DIR
    chown -R oracle:root $CONTAINERCONFIG_LOG_DIR
else
    mkdir -p $CONTAINERCONFIG_DIR
    mkdir -p $CONTAINERCONFIG_LOG_DIR
    mkdir -p $CONTAINERCONFIG_DOMAIN_DIR
    chown -R oracle:root $CONTAINERCONFIG_DOMAIN_DIR
    chown -R oracle:root $CONTAINERCONFIG_DIR
    chown -R oracle:root $CONTAINERCONFIG_LOG_DIR
fi

echo ""
echo ""

export component=$component

echo "component=${component}"

# configuring wcc domain
sh /$vol_name/oracle/container-scripts/createWCCDomain.sh

retval=$?

if [ $retval -ne 0 ];
  then
   echo ""
    echo ""
    echo "Domain Creation failed. Exiting.."
    exit 1
fi

#component
export isIPM="false"
export isCAPTURE="false"
export isADFUI="false" 

#delimited code
IFS=',' read -r -a cmp <<< "$component"

size=${#cmp[@]}
echo "size of component=$size"

if [ $size -gt "0" ]
then
for i in "${cmp[@]}"
do
   
   if [ "${i^^}" == "IPM" ]
   then
     isIPM="true" 
     echo "Extending domain with WebCenter Imaging"
     sh /$vol_name/oracle/container-scripts/extendWithIPMDomain.sh
   fi

   if [ "${i^^}" == "CAPTURE" ]
   then
     isCAPTURE="true"
     echo "Extending domain with WebCenter Capture"
     sh /$vol_name/oracle/container-scripts/extendWithCaptureDomain.sh
     
   fi

  if [ "${i^^}" == "ADFUI" ]
   then
     isADFUI="true"
     echo "Extending domain with WebCenter ADFUI"
     sh /$vol_name/oracle/container-scripts/extendWithWCCADFDomain.sh
   fi
done
fi

echo "start admin container"
# start admin container
sh /$vol_name/oracle/container-scripts/startAdminContainer.sh
