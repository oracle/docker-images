#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2021 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2021
# Author: paramdeep.saini@oracle.com
# Description: Common functions for CMAN 
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

source /tmp/envfile

export logfile=/tmp/orod.log
export logdir=/tmp
export STD_OUT_FILE="/proc/self/fd/1"
export STD_ERR_FILE="/proc/self/fd/2"

###### Function Related to printing messages and exit the script if error occurred ##################
error_exit() {
local NOW=$(date +"%m-%d-%Y %T %Z")
        # Display error message and exit
#       echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        echo "${NOW} : ${PROGNAME}: ${1:-"Unknown Error"}" | tee -a $logfile  > $STD_OUT_FILE
        exit 15
}

print_message ()
{
        local NOW=$(date +"%m-%d-%Y %T %Z")
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
        local ip=$( getent hosts "$host" | awk '{print $1}' )
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
