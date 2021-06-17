#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

SCRIPT_DIR=$(cd $(dirname $0) > /dev/null; pwd)

. ${SCRIPT_DIR}/_essbase-functions

if [ ! -e "${DOMAIN_HOME}/esstools/bin/stop.sh" ]; then
   # Domain was not configured properly
   log "Domain is not configured. Ignoring..."
   exit
fi

exec ${DOMAIN_HOME}/esstools/bin/stop.sh
