#!/bin/bash
#
# Copyright (c) 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl.
#
# Script to check OUD instance
#

# Variables for this script to work
source ${SCRIPT_DIR}/setEnvVars.sh

outFile="/tmp/$(basename $0).$$"

# Run status on OUD Instance
${OUD_INST_HOME}/bin/status --script-friendly --no-prompt --noPropertiesFile > ${outFile} 2>&1
oudError=$?

# handle errors from OUD status
if [ ${oudError} -gt 0 ]; then
    echo "$0: Error ${oudError} running status command ${OUD_INST_HOME}/bin/status"
    exit 1
fi

# check Server Run Status
if [ $(grep -ic 'Server Run Status: Started' ${outFile}) -eq 0 ]; then
    echo "$0: Error OUD Instance ${OUD_INST_HOME} not running"
    exit 1
fi

if [ -e ${outFile} ]; then
	# cat ${outFile}
    rm ${outFile} 2>/dev/null
    # remove oud status temp file
    rm /tmp/oud-status*.log 2>/dev/null
fi

# exit with 0
exit 0
