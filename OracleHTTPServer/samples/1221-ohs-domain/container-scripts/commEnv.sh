#!/bin/bash
#
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
#*****************************************************************************
# This script is used to set up a common environment for starting WebLogic
# Server, as well as WebLogic development.
#*****************************************************************************
MW_HOME=/u01/oracle/ohssa
export MW_HOME
if [ -z "${MW_HOME}" -a -z "${WL_HOME}" ]; then
 echo "Please set MW_HOME or WL_HOME."
 exit 1
fi

if [ ! -z "${WL_HOME}" ]; then
  MW_HOME="${WL_HOME}/.."
else
  WL_HOME="${MW_HOME}/wlserver"
fi

export MW_HOME WL_HOME

. $MW_HOME/oracle_common/common/bin/commBaseEnv.sh
. $MW_HOME/oracle_common/common/bin/commExtEnv.sh
