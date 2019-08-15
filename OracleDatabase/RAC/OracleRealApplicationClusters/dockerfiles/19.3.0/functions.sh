#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Common Function File
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

export logfile=/tmp/orod.log
export logdir=/tmp
export STD_OUT_FILE="/proc/1/fd/1"
export STD_ERR_FILE="/proc/1/fd/2"
export TOP_PID=$$

###### Function Related to printing messages and exit the script if error occurred ##################
error_exit() {
local NOW=$(date +"%m-%d-%Y %T %Z")
        # Display error message and exit
#       echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        echo "${NOW} : ${PROGNAME}: ${1:-"Unknown Error"}" | tee -a $logfile > $STD_OUT_FILE 
        kill -s TERM $TOP_PID
}

print_message ()
{
        local NOW=$(date +"%m-%d-%Y %T %Z")
        # Display  message and return
        echo "${NOW} : ${PROGNAME} : ${1:-"Unknown Message"}" | tee -a $logfile > $STD_OUT_FILE
        return $?
}

#####################################################################################################

####### Function related to  IP Checks ###############################################################

validating_env_vars ()
{
local stat=3
local ip="${1}"
local alive="${2}"

print_message "checking IP is in correct format such as xxx.xxx.xxx.xxx"

if valid_ip $ip; then
        print_message "IP $ip format check passed!"
else
       error_exit "IP $ip is not in correct format..please check!"
fi

# Checking if Host is alive

if [ "${alive}" == "true" ]; then

print_message "Checking if IP is pingable or not!"

if host_alive $ip; then
        print_message  "IP $ip is pingable ...check passed!"
else
        error_exit  "IP $ip is not pingable..check failed!"
fi

else

print_message "Checking if IP is pingable or not!"

if host_alive $ip; then
        error_exit  "IP $ip is already allocated...check failed!"
else
        print_message  "IP $ip is not pingable..check passed!"
fi

fi
}

check_interface ()
{
local ethcard=$1
local output

ip link show | grep $ethcard

output=$?

 if [ $output -eq 0 ];then
     return 0
 else
    return 1
 fi
}

valid_ip()
{
    local  ip=$1
    local  stat=1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

host_alive()
{

        local ip_or_hostname=$1
        local stat=1
ping -c 1 -W 1 $ip_or_hostname  >& /dev/null

if [ $? -eq 0 ]; then
  stat=0
  return $stat
else
  stat=1
  return $stat
fi

}

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

##################################################################################################################

############################################Match an Array element#######################
isStringExist ()
{
local checkthestring="$1"
local stringtocheck="$2"
local stat=1

IFS=', ' read -r -a string_array   <<< "$checkthestring"

for ((i=0; i < ${#string_array[@]}; ++i)); do
    if [ ${stringtocheck} == ${string_array[i]} ]; then
            stat=0
    fi
done
 return $stat
}


#########################################################################################


##################################################Password function##########################

setpasswd ()
{

local user=$1
local pass=$2
echo $pass | passwd $user  --stdin
}

##############################################################################################
