#!/bin/bash
#
# Copyright (c) 2019, 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Description: This script is used for packaging wcs-wls-docker-install.jar using the official Groovy Docker image.
#

cd /wcs-wls-docker-install/

groovyc src/main/groovy/com/oracle/wcsites/install/*

jar cfm wcs-wls-docker-install.jar Manifest.txt com/oracle/wcsites/install/*.class

rm -rf com/
