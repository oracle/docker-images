#!/bin/bash
#
# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
# 
# This script is used to attempt to gracefully shutdown the Tuxedo server before its pod is deleted.
# It assumes that TUXDIR has been set

export APPDIR=/u01/data/bankapp/
LOG_FILE="${APPDIR}/stop_server.log"

# shellcheck disable=SC1091
source "${APPDIR}/bankvar.new"

echo "Server shutdown initiated at $(date)" >> $LOG_FILE

# Shutdown the domain
tmshutdown -y

touch "${SHUTDOWN_MARKER_FILE}"
