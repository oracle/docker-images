#!/bin/sh

# Copyright (c) 2023, 2025 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


if test "$1" = "9"
then
    echo "Building Oracle JDK 21 on Oracle Linux 9"
    docker build --file Dockerfile.ol9 --tag oracle/jdk:21-ol9 .
else
    echo "Building Oracle JDK 21 on Oracle Linux 8"
    docker build --file Dockerfile.ol8 --tag oracle/jdk:21-ol8 .
fi