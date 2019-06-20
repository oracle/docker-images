#!/bin/sh
#
#Copyright (c) 2014, 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
docker build --build-arg APPLICATION_NAME=sample --build-arg APPLICATION_PKG=archive.zip -t 12213-domain-with-app .
