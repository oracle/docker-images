#!/bin/bash
#
# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
# 
# This script is used to attempt to gracefully shutdown the Tuxedo server 
# before its pod is deleted.
# It assumes that TUXDIR has been set

SERVER_HOME=/u01/oracle/user_projects/ws_svr/
STOP_OUT_FILE="${SERVER_HOME}/stop.out"

# shellcheck disable=SC1091
source "${SERVER_HOME}/setenv.sh"

echo "stop server script kicked off at $(date)." > ${STOP_OUT_FILE}

# Shutdown the domain
tmshutdown -y

touch "${SHUTDOWN_MARKER_FILE}"
