#!/bin/sh
#
#Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
rm -Rf ${scriptDir}/archive
mkdir -p ${scriptDir}/archive/wlsdeploy/applications
jar cvf ${scriptDir}/archive/wlsdeploy/applications/simple-app.war -C ${scriptDir} simple-app/* 
jar cvf ${scriptDir}/archive.zip  -C ${scriptDir}/archive wlsdeploy
