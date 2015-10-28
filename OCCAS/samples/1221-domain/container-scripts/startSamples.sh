#!/bin/bash
if [ -z "${ORACLE_HOME}"  ]; then
 echo "ORACLE_HOME is not set."
 exit 1
fi


. "${ORACLE_HOME}/wlserver/samples/server/setExamplesEnv.sh"

ant single.server.sample
