#!/bin/bash
# Copyright (c) 2020, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
if [ -z "${MW_HOME}" -a -z "${WL_HOME}" ]; then
 echo "MW_HOME or WL_HOME is not set."
 exit 1
fi

if [ -z "${MW_HOME}" ]; then
  MW_HOME="${WL_HOME}/.."
fi

# SET HERE PRE_CLASSPATH
#PRE_CLASSPATH=$MW_HOME/oracle_common/modules/javax.persistence_2.1.jar:$MW_HOME/wlserver/modules/com.oracle.weblogic.jpa21support_1.0.0.0_2-1.jar

. "${MW_HOME}/oracle_common/common/bin/commEnv.sh"
