#!/bin/bash
#
#############################
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################
#
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

export CONFIGENV=${CONFIGENV:-/dnsserver/env}
export ENVFILE="${CONFIGENV}"/"dns_envfile"
# shellcheck disable=SC1090
source "${ENVFILE}"

export logdir=${LOGDIR:-/dnsserver/logs}
export logfile=${logdir}/orod.log
export STD_OUT_FILE="/proc/self/fd/1"
export STD_ERR_FILE="/proc/self/fd/2"

###### Function Related to printing messages and exit the script if error occurred ##################
error_exit() {
        local NOW
        NOW=$(date +"%m-%d-%Y %T %Z")
        # Display error message and exit
#       echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        echo "${NOW} : ${PROGNAME}: ${1:-"Unknown Error"}" | tee -a $logfile  > $STD_OUT_FILE
        exit 15
}

print_message ()
{
        local NOW
        NOW=$(date +"%m-%d-%Y %T %Z")
        # Display  message and return
        echo "${NOW} : ${PROGNAME} : ${1:-"Unknown Message"}" | tee -a $logfile  > $STD_OUT_FILE
        return $?
}

#####################################################################################################

####### Function related to  IP Checks ###############################################################
resolveip(){

    local host="$1"
    if [ -z "$host" ]
    then
        return 1
    else
        local ip
        ip=$(getent hosts "$host" | awk '{print $1}')
        if [ -z "$ip" ] 
        then
            ip=$( dig +short "$host" )
            if [ -z "$ip" ]
            then
                print_message "unable to resolve '$host'" 
                return 1
            else
                print_message "$ip"
                return 0
            fi
        else
            print_message "$ip"
            return 0
        fi
    fi
}
