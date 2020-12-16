#!/bin/sh

# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

if test "$1" = "slim-8"
then
	echo "Building Oracle Server JRE 8 on Oracle Linux 8 slim"
	docker build --file Dockerfile.slim-8 --tag oracle/serverjre:8-oraclelinux8 .
else
	echo "Building Oracle Server JRE 8 on Oracle Linux 7 slim"
	docker build --tag oracle/serverjre:8 .
fi

