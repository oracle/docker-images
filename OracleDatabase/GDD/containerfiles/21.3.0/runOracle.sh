#!/bin/bash
# LICENSE UPL 1.0
# Since: November, 2020
# Author: paramdeep.saini@oracle.com
# Description: Build script for building RAC container image
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2020,2021 Oracle and/or its affiliates.
#
# shellcheck disable=SC2164

#This is the main file which calls other file to setup the sharding.
if [ -z "${SHARD_SCRIPT_DIR}" ]; then
    SHARD_SCRIPT_DIR=$INSTALL_DIR/sharding
fi

if [ -z "${BASE_DIR}" ]; then
    if [ -f "$SHARD_SCRIPT_DIR/main.py" ]; then
        BASE_DIR=$SHARD_SCRIPT_DIR
    else
        BASE_DIR=$SHARD_SCRIPT_DIR/scripts
    fi
fi

if [ -z ${MAIN_SCRIPT} ]; then
    SCRIPT_NAME="main.py"
fi

if [ -z ${EXECUTOR} ]; then
    EXECUTOR="python"
fi

GSM_STARTUP_FAILURE_MARKER="${GSM_STARTUP_FAILURE_MARKER:-/tmp/gsm-startup.failed}"
ENABLE_DEBUG="${ENABLE_DEBUG:-false}"

function debug_hold_on_error() {
    local exit_code="$1"
    echo "#####################################"
    echo "########### E R R O R ###############"
    echo "GSM startup failed with exit code: ${exit_code}"
    echo "ENABLE_DEBUG=true, keeping container alive for debugging."
    echo "Marker file: ${GSM_STARTUP_FAILURE_MARKER}"
    echo "Useful logs:"
    echo "  - GSM alert logs: ${ORACLE_BASE}/diag/gsm/*/*/trace/alert*.log"
    echo "########### E R R O R ###############"
    echo "#####################################"
    tail -f /dev/null
}

rm -f "$GSM_STARTUP_FAILURE_MARKER"
cd "$BASE_DIR"
$EXECUTOR "$SCRIPT_NAME"
retcode=$?

if [ ${retcode} -ne 0 ]; then
    touch "$GSM_STARTUP_FAILURE_MARKER"
    if [ "${ENABLE_DEBUG}" = "true" ]; then
        debug_hold_on_error "${retcode}"
    fi
    exit ${retcode}
fi

rm -f "$GSM_STARTUP_FAILURE_MARKER"

# Tail on alert log and wait (otherwise container will exit)

if [ -z ${DEV_MODE} ]; then
 echo "The following output is now a tail of the alert.log:"
 tail -f $ORACLE_BASE/diag/gsm/*/*/trace/alert*.log &
else
 echo "The following output is now a tail of the /etc/passwd for dev mode"
 tail -f /etc/passwd &
fi
 
childPID=$!
wait $childPID
