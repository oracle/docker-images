#!/bin/bash

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

