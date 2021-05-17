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

if [ ! -z ${CLONE_DB} ]; then
 if [ ${CLONE_DB^^} == "TRUE" ]; then
  echo "The following output is now a tail of the alert.log:"
  tail -f $ORACLE_BASE/diag/rdbms/*/*/trace/alert*.log &
 fi
fi

if [ ! -z ${OP_TYPE} ]; then  
 if [ ${OP_TYPE,,} == "standbyshard" ]; then
   echo "The following output is now a tail of the alert.log:"
   tail -f $ORACLE_BASE/diag/rdbms/*/*/trace/alert*.log &  
 fi
fi

childPID=$!
wait $childPID
