#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# This script runs the oig schema patching after the creation of RCU schemas. It can't be used directly.
# WDT create domain tool will invoke this script, if mentioned in OIG custom type definition, to patch the created schemas in db.

cd /u01/oracle/oracle_common/modules/thirdparty/org.apache.ant/1.10.5.0.0/apache-ant-1.10.5/bin || exit 1

touch /u01/oracle/idm/server/bin/patch_oim_wls.log
chmod 777 /u01/oracle/idm/server/bin/patch_oim_wls.log

if [ -z "$db_host" ]
then
  echo >&2 "db_host is unset. Ensure RCU secret is created with name <domain_uid>-rcu-credentials and key db_host is present"
  exit 1
fi

if [ -z "$db_port" ]
then
  echo >&2 "db_port is unset. Ensure RCU secret is created with name <domain_uid>-rcu-credentials and key db_port is present"
  exit 1
fi

if [ -z "$db_service" ]
then
  echo >&2 "db_service is unset. Ensure RCU secret is created with name <domain_uid>-rcu-credentials and key db_service is present"
  exit 1
fi

if [ -z "$rcu_prefix" ]
then
  echo >&2 "rcu_prefix is unset. Ensure RCU secret is created with name <domain_uid>-rcu-credentials and key rcu_prefix is present"
  exit 1
fi

if [ -z "$rcu_schema_password" ]
then
  echo >&2 "rcu_schema_password is unset. Ensure RCU secret is created with name <domain_uid>-rcu-credentials and key rcu_schema_password is present"
  exit 1
fi


/u01/oracle/oracle_common/modules/thirdparty/org.apache.ant/1.10.5.0.0/apache-ant-1.10.5/bin/ant \
-f /u01/oracle/idm/server/setup/deploy-files/automation.xml \
run-patched-sql-files \
-logger org.apache.tools.ant.NoBannerLogger \
-logfile /u01/oracle/idm/server/bin/patch_oim_wls.log \
-DoperationsDB.host="$db_host" \
-DoperationsDB.port="$db_port" \
-DoperationsDB.serviceName="$db_service" \
-DoperationsDB.user="$rcu_prefix"_OIM \
-DOIM.DBPassword="$rcu_schema_password" \
-Dojdbc=/u01/oracle/oracle_common/modules/oracle.jdbc/ojdbc8.jar

retval=$?
if [ $retval -ne 0 ];
 then
   echo "ERROR: Something wrong while running OIM schema patching. Please check the logs at /u01/oracle/idm/server/bin/patch_oim_wls.log"
   exit 4
fi

echo "DB schema patching successful"
echo "-------------"
cat /u01/oracle/idm/server/bin/patch_oim_wls.log

