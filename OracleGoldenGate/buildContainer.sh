#!/bin/bash
#
# Since: April, 2016
# Author: rick.michaud@oracle.com
# Description: Build script for building Oracle Database Containers 
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#

help () {
cat << EOF
	Usage: ${0##*/} [-h] [-C CONTAINER_NAME] [-H HOST]  [-S ORACLE_SID] [-P ORACLE_PDB] [-p PASSWORD]

	This helps to build a container for the Oracle Database and GoldenGate docker image so that multiple environments
	can be quickly built ready to use.

	-h 		Display this help and exit
	-C		(Uppercase) Specify the name of the docker container
	-H 		(Uppercase) Specify the host name of the docker container
	-S 		(Uppercase) Specify the Oracle Database SID/ServiceName
	-P		(Uppercase) Specify the Oracle Database Pluggable Database (PDB) Name
	-p 		(Lowercase) Specify the passwords for the Oracle Database sys/system accounts
EOF
exit 1
}

while getopts :h:C:H:S:P:p: opt; do
	case ${opt} in
	h ) 	help
		;;
	C )	CONTAINER=${OPTARG}
		echo "CONTAINER NAME		===> $CONTAINER"
		;;
	H )	HOST=${OPTARG}
		echo "HOST NAME		===> $HOST"
		;;
	S )	SID=${OPTARG}
		echo "ORACLE SID		===> $SID"
		;;
	P )	PDB=${OPTARG}
		echo "ORACLE PDB		===> $PDB" 
		;;
	p )	PASSWORD=${OPTARG}
		echo "PASSWORDS		===> $PASSWORD"
		;;
	* )
		echo "ERROR: Invalid option: \""$opt"\"" >&2
		help
	esac
done

echo "Running: docker run --name $CONTAINER -h $HOST -e ORACLE_SID=$SID -e ORACLE_PDB=$PDB -e ORACLE_PWD=$PASSWORD -P ogg-oracle:12.1.0.2-ee"
docker run --name $CONTAINER -h $HOST -e ORACLE_SID=$SID -e ORACLE_PDB=$PDB -e ORACLE_PWD=$PASSWORD -P ogg-oracle:12.1.0.2-ee
