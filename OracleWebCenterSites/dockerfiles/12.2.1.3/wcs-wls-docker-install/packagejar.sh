#!/bin/bash
#
# Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Description: This script is used fir packaging wcs-wls-docker-install.jar.
#

echo "Installing Groovy Started"

curl -s get.sdkman.io | bash

source "$HOME/.sdkman/bin/sdkman-init.sh"

sdk install groovy

echo "Installing Groovy Completed"

echo "Compiling Groovy Scripts"

groovyc src/main/groovy/com/oracle/wcsites/install/*

echo "Compiling Groovy Scripts Completed"

echo "Packaging jar started"

jar cfm wcs-wls-docker-install.jar Manifest.txt com/oracle/wcsites/install/*.class

echo "Packaging jar completed"

rm -rf com/