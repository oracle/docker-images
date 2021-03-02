#!/bin/sh

# Copyright 2020 Oracle and/or its affiliates. 
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

if test "$1" = "8-slim"
then
	echo "Building OpenJDK 15 on Oracle Linux 8 slim"
	docker build --file Dockerfile.8-slim --tag oracle/openjdk:15-oraclelinux8 .
else
	echo "Building OpenJDK 15 on Oracle Linux 7 slim"
	docker build --tag oracle/openjdk:15 --tag oracle/openjdk:15-oraclelinux7 .
fi
