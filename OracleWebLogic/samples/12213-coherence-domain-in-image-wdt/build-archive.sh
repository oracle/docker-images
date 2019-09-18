#!/bin/sh
#
#Copyright (c)  2019 Oracle and/or its affiliates. All rights reserved.
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

cd ${scriptDir}

# make coherence server gar
cd coh-proxy-server
mvn clean package -DskipTests=true
cd ../

# build the archive
rm archive.zip
rm -f wlsdeploy
mkdir -p wlsdeploy/applications
cp coh-proxy-server/target/coh-proxy-server.gar wlsdeploy/applications
zip -r archive.zip wlsdeploy

#
#${JAVA_HOME}/bin/jar cvf ${scriptDir}/archive/wlsdeploy/applications/simple-app.war -C ${scriptDir} simple-app/*
#${JAVA_HOME}/bin/jar cvf ${scriptDir}/archive.zip  -C ${scriptDir}/archive wlsdeploy
#
#
#mkdir -p wlsdeploy/applications
#cp ~/coh.gar  wlsdeploy/applications
#zip -r archive.zip wlsdeploy
