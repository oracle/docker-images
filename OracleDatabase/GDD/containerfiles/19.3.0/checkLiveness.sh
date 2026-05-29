#!/bin/bash

export PYTHON="/bin/python"
GSM_STARTUP_FAILURE_MARKER="${GSM_STARTUP_FAILURE_MARKER:-/tmp/gsm-startup.failed}"
ENABLE_DEBUG="${ENABLE_DEBUG:-false}"

if [ "${ENABLE_DEBUG}" = "true" ] && [ -f "$GSM_STARTUP_FAILURE_MARKER" ]; then
    echo "GSM startup failure marker found and ENABLE_DEBUG=true; bypassing liveness for debugging."
    exit 0
fi

if [ -z "${SHARD_SCRIPT_DIR}" ]; then
    SHARD_SCRIPT_DIR=$SCRIPT_DIR
fi

if [ -f "$SHARD_SCRIPT_DIR/$MAINPY" ]; then
    CHECK_SCRIPT="$SHARD_SCRIPT_DIR/$MAINPY"
else
    CHECK_SCRIPT="$SHARD_SCRIPT_DIR/scripts/$MAINPY"
fi

$PYTHON "$CHECK_SCRIPT" --checkliveness='true'
retcode=$?

 if [ ${retcode} -eq 0 ]; then
    exit 0
 else
    exit 1
 fi
