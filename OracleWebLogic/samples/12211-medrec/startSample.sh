#!/bin/sh
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#

# Define default command to create medrec domain 
USERNAME=${USERNAME:-weblogic}
PASSWORD=${PASSWORD:-welcome1}
${ORACLE_HOME}/wlserver/samples/server/run_samples.sh "${USERNAME}" "${PASSWORD}"
${ORACLE_HOME}/wlserver/samples/domains/medrec/startWebLogic.sh
