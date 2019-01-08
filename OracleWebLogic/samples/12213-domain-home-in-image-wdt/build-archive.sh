#!/bin/sh
#
#Copyright (c) 2018, 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# This script requires the following environment variables:
#
# JAVA_HOME            - The location of the JDK to use.  The caller must set
#                        this variable to a valid Java 8 (or later) JDK.
#

if [ -z ${JAVA_HOME} ] || [ ! -e ${JAVA_HOME}/bin/jar ]; then 
   echo "JAVA_HOME must be set to version of a java JDK 1.8 or greater"
   exit 1
fi
echo JAVA_HOME=${JAVA_HOME}

scriptDir="$( cd "$( dirname $0 )" && pwd )"
if [ ! -d ${scriptDir} ]; then
    echo "Unable to determine the sample directory where the application is found"
    echo "Using shell /bin/sh to determine and found ${scriptDir}"
    exit 1
fi

rm -Rf ${scriptDir}/archive
mkdir -p ${scriptDir}/archive/wlsdeploy/applications
${JAVA_HOME}/bin/jar cvf ${scriptDir}/archive/wlsdeploy/applications/simple-app.war -C ${scriptDir} simple-app/* 
${JAVA_HOME}/bin/jar cvf ${scriptDir}/archive.zip  -C ${scriptDir}/archive wlsdeploy
