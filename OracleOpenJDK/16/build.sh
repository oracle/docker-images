#!/bin/sh

# Copyright 2021 Oracle and/or its affiliates. 
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo "Building OpenJDK 16 on Oracle Linux 8 slim"
docker build --file Dockerfile --tag oracle/openjdk:16 --tag oracle/openjdk:16-oraclelinux8 .
