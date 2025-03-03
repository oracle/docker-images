#!/bin/sh

# Copyright (c) 2023 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo "Building OpenJDK 23 on Oracle Linux 9"
docker build --file Dockerfile.ol9 --tag oracle/openjdk:23-ol9 .
