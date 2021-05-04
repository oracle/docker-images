#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
#
# Since: Mar, 2021
# Author: Paramdeep.saini@oracle.com
# Description: Runs the Oracle Database inside the container
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

if [ ${SHARD_SETUP,,} == "true" ]; then

sh $ORACLE_BASE/scripts/sharding/runOraShardSetup.sh

fi
