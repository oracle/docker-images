#!/bin/bash
#
# Copyright (c) 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl.
#
# Script to generate start-ds_debug 
# 

usage() {
		echo "Usage: $0 <Path of BIN direcotry of OUD Instance> [Port to Start Debug Server] [Value for suspend parameter]"
		echo "Please make sure that <Path of BIN direcotry of OUD Instance>/start-ds is accessible"
		exit
}

oudInstBinDir=$1
debugPort=${2:-1044}
debugSuspendParam=${3:-y}

#echo "oudInstBinDir [$oudInstBinDir], debugPort [$debugPort], debugSuspendParam [$debugSuspendParam]"

if [ "$oudInstBinDir" = "" ] || [ ! -d "$oudInstBinDir" ] || [ ! -e "$oudInstBinDir/start-ds" ]
then
		usage
fi

startDs=${oudInstBinDir}/start-ds
startDsDebug=${oudInstBinDir}/start-ds_debug

#echo "startDs [${startDs}], startDsDebug [${startDsDebug}]"

lNo2BreakScript=`grep -n "org.opends.server.core.DirectoryServer" ${startDs} | head -1 | cut -d':' -f 1`
lines4Head=$(( lNo2BreakScript - 1 ))
fileLength=`cat ${startDs} | wc -l`
lines4Tail=$(( fileLength - lines4Head ))

cat ${startDs} | head -`echo $lines4Head` > ${startDsDebug}

#Insert following in the script file
#DEBUG_ARGS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=1044"
#OPENDS_JAVA_ARGS="${OPENDS_JAVA_ARGS} ${DEBUG_ARGS}"
#echo "Updated OPENDS_JAVA_ARGS for Debug [${OPENDS_JAVA_ARGS}]"

echo "" >> ${startDsDebug}
echo "# Modifications for starting debug server with java process of OUD" >> ${startDsDebug}
echo "# This file is generated using util script $0" >> ${startDsDebug}
echo "DEBUG_ARGS=\"-agentlib:jdwp=transport=dt_socket,server=y,suspend=${debugSuspendParam},address=${debugPort}\"" >> ${startDsDebug}
echo 'OPENDS_JAVA_ARGS="${OPENDS_JAVA_ARGS} ${DEBUG_ARGS}"' >> ${startDsDebug}
echo 'echo "Updated OPENDS_JAVA_ARGS for Debug [${OPENDS_JAVA_ARGS}]"' >> ${startDsDebug}
echo "" >> ${startDsDebug}

cat ${startDs} | tail -`echo $lines4Tail` >> ${startDsDebug}

chmod +x ${startDsDebug}

echo "Diff: [${startDs}] and [${startDsDebug}]"
diff ${startDs} ${startDsDebug}
