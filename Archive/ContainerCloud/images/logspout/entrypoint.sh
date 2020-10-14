#!/bin/sh

echo "$KV_IP"
echo "Searching for <$OCCS_LOGSTASH_KEY> in the kv store"

i=0

while [ $i -le 1 ]
do
  echo "Logstash IP address: $OCCS_LOGSTASH_IP"

  if [ "$OCCS_LOGSTASH_IP" != "" ]; then
    echo "Setting logstash ip to $OCCS_LOGSTASH_IP"
    i=$((i+2))
  else
    echo "No logstash IP yet. Checking in 5 seconds"
    sleep 5
    OCCS_LOGSTASH_IP=$(curl -s ${KV_IP}:${KV_PORT}/v1/kv/${OCCS_LOGSTASH_KEY}?recurse | jq -r ".[].Value" | base64 -d)
  fi
done

/bin/logspout syslog://$OCCS_LOGSTASH_IP
