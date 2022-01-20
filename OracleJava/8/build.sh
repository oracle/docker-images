#!/bin/sh

# Copyright (c) 2019, 2022 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

if test "$1" = "8"
then
	echo "Building Oracle Server JRE 8 on Oracle Linux 8"
	docker build --file Dockerfile.8 --tag oracle/serverjre:8-oraclelinux8 .
else
	echo "Building Oracle Server JRE 8 on Oracle Linux 7 slim"
	docker build --tag oracle/serverjre:8 --tag oracle/serverjre:8-oraclelinux7 .
fi

