#!/bin/sh
#
#Copyright (c) 2014-2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Build the image using Dockerfile.patch-ontop-12213 to apply patch p29135930 based on WebLogic 12.2.1.3, or build 
# the image using Dockerfile.patch-ontop-12213-psu to apply patch p29135930  ontop of WebLogic 12.2.1.3 October PSU.
docker build --force-rm=true --no-cache=true -t oracle/weblogic:12213-patch-wls-for-k8s -f Dockerfile.$1 .
