#!/bin/sh
java -jar $KVHOME/lib/kvstore.jar makebootconfig \
  -root $KVROOT \
  -port 5000 \
  -admin 5001 \
  -host "$(hostname -f)" \
  -harange 5010,5020 \
  -store-security none \
  -capacity 1 \
  -num_cpus 0 \
  -memory_mb 0

java -jar $KVHOME/lib/kvstore.jar start -root $KVROOT &

sleep 5

tail -f $KVROOT/*.log
