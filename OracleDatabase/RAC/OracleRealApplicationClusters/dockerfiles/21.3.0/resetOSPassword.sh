#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2018,2021 Oracle and/or its affiliates.
# 
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Reset the password for Grid and oracle user
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

declare -a cluster_nodes
GRID_USER='grid'
DB_USER='oracle'
PROGNAME=$(basename "$0")
PWD_KEY='pwd.key'
SECRET_VOLUME='/run/secrets'
declare -x REMOVE_OS_PWD_FILES='false'
PASSWD_VALUE="NOPASSWD"
source /etc/rac_env_vars

###################Capture Process id and source functions.sh###############
source "$SCRIPT_DIR/functions.sh"
###########################sourcing of functions.sh ends here##############

####error_exit function sends a TERM signal, which is caught by trap command and returns exit status 15"####
trap '{ exit 15; }' TERM
###########################trap code ends here##########################

generate_pwd ()
{

if [ -f "${SECRET_VOLUME}/${PWD_FILE}" ] && [ -f "${SECRET_VOLUME}/${PWD_KEY}" ] ; then
cmd='openssl enc -d -aes-256-cbc -in "${SECRET_VOLUME}/${PWD_FILE}" -out /tmp/${PWD_FILE} -pass file:"${SECRET_VOLUME}/${PWD_KEY}"'

eval $cmd

if [ $? -eq 0 ]; then
print_message "Password file generated"
else
error_exit "Error occurred during common os password file generation"
fi

read PASSWORD < /tmp/"${PWD_FILE}"
rm -f /tmp/"${PWD_FILE}"
rm -f /tmp/${PWD_KEY}

if [ "${REMOVE_OS_PWD_FILES}" == 'true' ]; then
rm -f  "${SECRET_VOLUME}"/"${COMMON_OS_PWD_FILE}"
rm -f ${SECRET_VOLUME}/${PWD_KEY}
fi

else
 print_message "Password file or password key file is empty string! generating random password"
 PASSWORD=O$(openssl rand -base64 6 | tr -d "=+/")_1
fi

if [ ! -z "${PASSWORD}" ]; then
  PASSWD_VALUE="${PASSWORD}"
fi

}

setNode () {
if [ ! -f "$GRID_HOME"/bin/olsnodes ]; then
cluster_nodes=( $(hostname) )
else
cluster_nodes=( $("$GRID_HOME"/bin/olsnodes | awk '{ print $1 }') )
node_count=$("$GRID_HOME"/bin/olsnodes -a | awk '{ print $1 }' | wc -l)
fi
}

reset_passwd ()
{
user=${1}
password=${2}

if [ -z "${user}" ]; then
error_exit "user name is not specified. It must be set to oracle|grid"
fi

if [ -z "${password}" ]; then
error_exit "password string is not specified"
fi

for node in "${cluster_nodes[@]}"
do
if [ ! -f "$GRID_HOME"/bin/olsnodes ]; then
print_message "Resetting password for ${user} on the ${node}"
cmd='su - $user -c "echo $password | sudo passwd $user  --stdin"'
else
print_message "Resetting password for ${user} on all the ${node}"
cmd='su - $user -c "ssh ${node} \"echo $password | sudo passwd $user  --stdin\""'
fi

eval $cmd

if [ $? -eq 0 ]; then
print_message "Password reset seucessfuly on ${node} for $user"
else
print_message "Password reset failed on ${node} for $user"
fi
done
}

usage() {
cat << EOF
Usage: -o|--op_type              Specify the value  reset_grid_oracle|reset_grid|reset_oracle
       -p|--pwd_file             Specify the encrypted password file name 
       -k|--pwd_key_file          Specify password key fle
       -s|--secret_volume        Specify the secret volume
       -r|--remove_os_pwd_files  Remove the passwordfiles after resetting the password
       -h|--help                 Show help
EOF
error_exit "Please specify correct parameters"
}

#####################################################################
###                       MAIN                                      # 
#####################################################################

SHORTOPTS="o:p:k:s:r:h"
LONGOPTS="help,op_type:,pwd_key_file:,pwd_file:,secret_volume:,remove_os_pwd_files:"

ARGS=$(getopt -o $SHORTOPTS --long $LONGOPTS --name "$PROGNAME" -- "$@" )

if [ $? != 0 ] ; then 
error_exit  "Terminating... as error occurred during ARGS computation"; 
fi

print_message "$ARGS"

eval set -- "$ARGS"

while true; do
case "$1" in
  --help)
   usage
;;
 -o | --op_type)
  if [ "$2" ]; then
    RESET_PASSWORD_TYPE=$2
 else
   error_exit  "--op_type requires non empty option argument"
 fi
   print_message "RESET_PASSWORD_TYPE=${RESET_PASSWORD_TYPE}"
   shift 2
;;
 -p | --pwd_file)
  if [ "$2" ]; then
   PWD_FILE=$2
  else
    print_message "--pwd_file set to empty string. random password will generated"
  fi
   print_message "PWD_FILE: $PWD_FILE"
   shift 2
;;
-k | --pwd_key_file)
 if [ "$2" ];then
   PWD_KEY=$2
 else
  PWD_KEY='pwd.key'
  print_message "--pwd_key set to empty string. It will be set to default value ${PWD_KEY}"
 fi
  print_message "PWD_KEY=$PWD_KEY"
  shift 2
;;
 -s | --secret_volume)
 echo "Secret Volume Location"
 if [ "$2" ];then
  SECRET_VOLUME=$2
 else
  SECRET_VOLUME='/run/secrets'
  print_message  "--secret_volume is set to empty string. It will be set to default value ${SECRET_VOLUME}"
 fi
  shift 2
;;
-r| --remove_os_pwd_files)
 echo "Remove OS PWD files after resetting password"
 if [ "${2}" == 'true' ]; then
    REMOVE_OS_PWD_FILES='true'
 else
    REMOVE_OS_PWD_FILES='false'
 fi
  shift 2
;;
 --)
         shift;
         break;
;;
*)
print_message "Not a valid option"
usage
;;
esac
done

print_message "generating node name from the cluster"
setNode
print_message "Generating password for grid and oracle user"
generate_pwd

if [ "${PASSWD_VALUE}" == "NOPASSWD" ]; then
 error_exit "Correct password string is not set"
fi

if [ "${RESET_PASSWORD_TYPE}" == 'reset_grid_oracle' ]; then
print_message "Setting password for $GRID_USER user"
reset_passwd $GRID_USER  "$PASSWD_VALUE"
print_message "Setting password for $DB_USER user"
reset_passwd  $DB_USER "$PASSWD_VALUE"
elif [ "${RESET_PASSWORD_TYPE}" == 'reset_grid' ]; then 
  print_message "Setting password for $GRID_USER user"
  reset_passwd  $GRID_USER "$PASSWD_VALUE"
elif [ "${RESET_PASSWORD_TYPE}" == 'reset_oracle' ]; then
  print_message "Setting password for $DB_USER user"
  reset_passwd  $DB_USER "$PASSWD_VALUE"
else
error_exit "Please specify correct value for RESET_PASSWORD_TYPE. Correct Values are reset_grid_oracle|reset_grid|reset_oracle"
fi
