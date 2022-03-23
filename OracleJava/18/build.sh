#!/bin/sh

# Copyright (c) 2022 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo "Building Oracle JDK 18 on Oracle Linux 8"
docker build --file Dockerfile --tag oracle/jdk:18  --tag oracle/jdk:18-oraclelinux8 .