#! /usr/bin/bash

ms_name_from_image=${DEFAULT_MS_NAME}
number_of_ms=${NUMBER_OF_MS}
ms_name=${MS_NAME:-ms$(( ( RANDOM % $number_of_ms )  + 1 ))}
domain_home=${DOMAINS_DIR}/${DOMAIN_NAME}

echo "Launching with parameters"
echo "Domain Home: " $domain_home
echo "MS Name from Image: " $ms_name_from_image
echo "MS Name to be used: " $ms_name
echo "Number of servers configured in image: " $number_of_ms

cd $domain_home

# Rename the server directory
if [ "$ms_name_from_image" != "$ms_name" ]; then
  echo "Setting up server name as $ms_name"
  mv servers/$ms_name_from_image servers/$ms_name
fi

# Relays SIGTERM to all java processes
function relay_SIGTERM {
  pid=`grep java /proc/[0-9]*/comm | awk -F / '{ print $3; }'`
  echo "Sending SIGTERM to java process " $pid
  kill -SIGTERM $pid
}

trap relay_SIGTERM SIGTERM

bin/startManagedWebLogic.sh $ms_name &
while true
do
  tail -f /dev/null & wait ${!}
done
