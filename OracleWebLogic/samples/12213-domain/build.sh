#! /bin/bash
#
#Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#Build WebLogic Domain image persisted to volume

docker build -f Dockerfile -t 12213-weblogic-domain-in-volume .
