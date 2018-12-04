#!/bin/sh
#
#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
. ./container-scripts/setEnv.sh ./properties/docker_build/domain.properties

docker build $BUILD_ARG -t 12213-domain-home-in-image .
