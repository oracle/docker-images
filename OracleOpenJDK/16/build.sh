#!/bin/sh

# Copyright 2021 Oracle and/or its affiliates. 
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

if test "$1" = "7-slim"
then
	echo "Building OpenJDK 16 on Oracle Linux 7 slim"
	docker build --file Dockerfile.7-slim --tag oracle/openjdk:16-oraclelinux7 .
else
	echo "Building OpenJDK 16 on Oracle Linux 8 slim"
	docker build --file Dockerfile --tag oracle/openjdk:16 --tag oracle/openjdk:16-oraclelinux8 .
fi
