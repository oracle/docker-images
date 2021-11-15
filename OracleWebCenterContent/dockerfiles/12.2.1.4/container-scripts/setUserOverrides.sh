#!/bin/sh
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#

echo ""
echo "Setting from UserOverrides.sh"

# global settings (for all managed servers)

export JAVA_OPTIONS="$JAVA_OPTIONS -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${DOMAIN_HOME}/java_heapdump.hprof"

echo "Removing proxy settings."

unset http_proxy
unset https_proxy

echo "End setting from UserOverrides.sh"
echo ""

