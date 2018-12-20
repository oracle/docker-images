#!/bin/sh
#
#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
docker build -t oracle/weblogic:12213-patch-wls-for-k8s -f $DOCFILE .
