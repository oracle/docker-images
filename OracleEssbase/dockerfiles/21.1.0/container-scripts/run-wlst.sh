#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

if [ "$ORACLE_HOME" == "" ]; then
   echo "Must set ORACLE_HOME env variable"
   exit 1
fi

# Execute the standard WLST tooling with some additional settings
WLST_PROPERTIES="-Djava.security.egd=file:/dev/./urandom -Doracle.jdbc.fanEnabled=false ${WLST_PROPERTIES}"
export WLST_PROPERTIES

exec ${ORACLE_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning "$@"
