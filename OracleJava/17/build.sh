#!/bin/sh

# Copyright (c) 2021, 2022 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo "Building Oracle JDK 17 on Oracle Linux 8"
docker build --file Dockerfile --tag oracle/jdk:17  --tag oracle/jdk:17-oraclelinux8 .