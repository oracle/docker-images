#!/bin/sh
#
#Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
docker build \
    --build-arg WDT_MODEL=simple-topology.yaml \
    --build-arg WDT_ARCHIVE=archive.zip \
    -t 12213-domain-wdt .

