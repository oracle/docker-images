#!/bin/sh

# Copyright (c) 2024,2025 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo "Building Oracle JDK 24 on Oracle Linux 9"
docker build --file Dockerfile.ol9 --tag oracle/jdk:24-ol9 .