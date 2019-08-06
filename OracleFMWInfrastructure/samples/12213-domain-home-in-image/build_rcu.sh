#! /bin/bash
#
#Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#Build image to run RCU
docker build -f Dockerfile.rcu -t 12213-fmw-rcu .
