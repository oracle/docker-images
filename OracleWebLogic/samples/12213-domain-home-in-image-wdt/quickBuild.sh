#!/bin/sh
#
#Copyright (c) 2018, 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Build the sample domain home image. You must build the archive file and download the weblogic deploy
# install image prior to executing this shell script.

# parse the ADMIN_HOST, ADMIN_PORT, MS_PORT, and DOMAIN_NAME from the sample properties file and pass
# as a string of --build-arg in the variable BUILD_ARG
. container-scripts/setEnv.sh properties/docker-build/domain.properties


docker build \
    $BUILD_ARG \
    --build-arg WDT_MODEL=simple-topology.yaml \
    --build-arg WDT_VARIABLE=properties/docker-build/domain.properties \
    --build-arg WDT_ARCHIVE=archive.zip \
    --force-rm=true \
    --no-cache=true \
    -t 12213-domain-home-in-image-wdt .

