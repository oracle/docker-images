#!/bin/sh

# Copyright (c) 2023 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo "Building Oracle JDK 21 on Oracle Linux 8"
docker build --file Dockerfile --tag oracle/jdk:21-ol8 .