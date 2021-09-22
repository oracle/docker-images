#!/bin/sh

# Copyright 2021 Oracle and/or its affiliates. 
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo "Building OpenJDK 17 on Oracle Linux 8"
docker build --file Dockerfile --tag oracle/openjdk:17 --tag oracle/openjdk:17-oraclelinux8 .
