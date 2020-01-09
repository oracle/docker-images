#!/bin/sh
#
#Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Build the image using Dockerfile to apply patch p29135930 based on FMW Infrastructure 12.2.1.3 
docker build --force-rm=true --no-cache=true -t oracle/fmw-infrastructure:12213-update-k8s .
