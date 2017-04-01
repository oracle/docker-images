#!/bin/sh
LOGNAME=`whoami`
ipcs -q | grep ${LOGNAME} | awk '{print "ipcrm -q "$2}' | sh 2>/dev/null
ipcs -m | grep ${LOGNAME} | awk '{print "ipcrm -m "$2}' | sh 2>/dev/null
ipcs -s | grep ${LOGNAME} | awk '{print "ipcrm -s "$2}' | sh 2>/dev/null

echo "IPC CLEAN: Clean Message Queue Successfully!"

