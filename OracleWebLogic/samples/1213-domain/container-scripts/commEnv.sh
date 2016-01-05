# Modified commEnv.sh to enable JPA 2.1 support by default on this WLS installation
#
# Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
#
# =========================

if [ -z "${MW_HOME}" -a -z "${WL_HOME}" ]; then
 echo "MW_HOME or WL_HOME is not set."
 exit 1
fi

if [ -z "${MW_HOME}" ]; then
  MW_HOME="${WL_HOME}/.."
fi

# SET HERE PRE_CLASSPATH
PRE_CLASSPATH=$MW_HOME/oracle_common/modules/javax.persistence_2.1.jar:$MW_HOME/wlserver/modules/com.oracle.weblogic.jpa21support_1.0.0.0_2-1.jar

. "${MW_HOME}/oracle_common/common/bin/commEnv.sh"
