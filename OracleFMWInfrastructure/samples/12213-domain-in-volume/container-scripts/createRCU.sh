#!/bin/bash
#
#
# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

echo "Loading RCU Phase"
echo "================="
RUN_RCU="true"
CONTAINERCONFIG_DIR=/u01/oracle/ContainerData

mkdir -p $ORACLE_HOME/properties
SEC_PROPERTIES_FILE=/u01/oracle/properties/rcu_security.properties
if [ ! -e "$SEC_PROPERTIES_FILE" ]; then
   echo "A properties file with the username and password needs to be supplied."
   exit
fi

# Get Database Username
DB_USER=`awk '{print $1}' $SEC_PROPERTIES_FILE | grep db_user | cut -d "=" -f2`
if [ -z "$DB_USER" ]; then
   echo "The domain username is blank.  The Admin username must be set in the properties file."
   exit
fi
# echo "Database Username $DB_USER"
# Get Database Password
DB_PASS=`awk '{print $1}' $SEC_PROPERTIES_FILE | grep db_pass | cut -d "=" -f2`
if [ -z "$DB_PASS" ]; then
   echo "The domain password is blank.  The Admin password must be set in the properties file."
   exit
fi
# echo "Database Password $DB_PASS"
# Get databasse Schema Password
DB_SCHEMA_PASS=`awk '{print $1}' $SEC_PROPERTIES_FILE | grep db_schema | cut -d "=" -f2`
if [ -z "$DB_SCHEMA_PASS" ]; then
   echo "The databse schema password is blank.  The database schema password must be set in the properties file."
   exit
fi
# echo "Database Schema Password: $DB_SCHEMA_PASS"

PROPERTIES_FILE=/u01/oracle/properties/rcu.properties
if [ ! -e "$PROPERTIES_FILE" ]; then
   echo "A properties file with the RCUPREFIX and the Connection String needs to be supplied."
   exit
fi
# Get RCUPREFIX
RCUPREFIX=`awk '{print $1}' $PROPERTIES_FILE | grep RCUPREFIX | cut -d "=" -f2`
if [ -z "$RCUPREFIX" ]; then
   echo "The RCUPREFIX is blank.  The RCUPREFIX must be set in the properties file."
   exit
fi
# echo "RCU Prefix: $RCUPREFIX"
# Get Database Connection String 
CONNECTION_STRING_=`awk '{print $1}' $PROPERTIES_FILE | grep CONNECTION_STRING | cut -d "=" -f2`
if [ -z "$CONNECTION_STRING" ]; then
   echo "The Connection String is blank.  The Connection String must be set in the properties file."
   exit
fi
# echo "Connection String: $CONNECTION_STRING"

export jdbc_url="jdbc:oracle:thin:@"$CONNECTION_STRING
# echo "JDBC URL: $jdbc_url"

#Only call RCU the first time we create the domain
if [ -e $CONTAINERCONFIG_DIR/RCU.$RCUPREFIX.suc ]
then
   #RCU has already been executed successfully, no need to rerun
   RUN_RCU="false"
   echo "SOA RCU has already been loaded.. skipping"
fi

if [ "$RUN_RCU" == "true" ]
then
   #Set the password for RCU
   echo -e ${DB_PASS}"\n"${DB_SCHEMA_PASS} > /u01/oracle/pwd.txt
   echo "Loading SOA RCU into database"
   # Run the RCU to load the schemas into the database
   /u01/oracle/oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE -connectString ${CONNECTION_STRING} -dbUser ${DB_USER} -dbRole sysdba -useSamePasswordForAllSchemaUsers true -selectDependentsForComponents true -schemaPrefix ${RCUPREFIX} -component MDS -component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS  -component WLS  -component STB -f < /u01/oracle/pwd.txt >> /u01/oracle/RCU.out
   retval=$?

   if [ $retval -ne 0 ];
   then
      echo  "RCU has some error "
      #RCU was already called once and schemas are in the database
      #continue with Domain creation
      grep -q "RCU-6016 The specified prefix already exists" "/u01/oracle/RCU.out"
      if [ $? -eq 0 ] ; then
         echo  "RCU has already loaded schemas into the Database"
         echo  "RCU Ignore error"
      else
         echo "RCU Loading Failed.. Please check the RCU logs"
         cat /u01/oracle/RCU.out
               exit
      fi
   fi
   echo "RCU ran successfully retval= $retval"

   # cleanup : remove the password file for security
   rm -f "/u01/oracle/pwd.txt"
fi
