#! /usr/bin/bash

domain_home=$1
ms_name_from_image=$2
username=$3
password=$4
number_of_ms=$5
ms_name=${MS_NAME:-ms$(( ( RANDOM % $number_of_ms )  + 1 ))}

cd $domain_home
# echo 'Working in location' `pwd`

# Rename the server directory
if [ "$ms_name_from_image" != "$ms_name" ]; then
  echo "Setting up server name as $ms_name"
  mv servers/$ms_name_from_image servers/$ms_name
fi

bin/startManagedWebLogic.sh $ms_name
