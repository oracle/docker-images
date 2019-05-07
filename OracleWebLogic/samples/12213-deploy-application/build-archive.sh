#!/bin/sh
#
#Copyright (c) 2018, 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

scriptDir="$( cd "$( dirname $0 )" && pwd )"
if [ ! -d ${scriptDir} ]; then
    echo "Unable to determine the sample directory where the application is found"
    echo "Using shell /bin/sh to determine and found ${scriptDir}"
    exit 1
fi

rm -Rf ${scriptDir}/archive
mkdir -p ${scriptDir}/app-archive
jar -cvf ${scriptDir}/app-archive/sample.war -C ${scriptDir}/sample .
jar -cvf ${scriptDir}/archive.zip  -C ${scriptDir}/app-archive/ sample.war
 
