#!/bin/sh
#
# Copyright (c) 2023 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: OIG Development
#
# Description: Script file for Creating a service account in EBS target For HRMS
#
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.


if [ -f run.sql ]
then
rm -f run.sql
fi

if [ -f "$ORACLE_HOME" ]
then
echo "Enter the ORACLE_HOME ::"
read -r orahome
ORACLE_HOME=$orahome
else
echo "ORACLE_HOME is ::"
echo "$ORACLE_HOME"
fi

export ORACLE_HOME

echo Enter the System User Name ::
read -r Systemuser

echo Enter the name of the database ::
read -r Databasename

# ---- User Input to choose Connector  ----

# ---- Create Log file ----
echo SPOOL OIM_APPS_HRMS_TARGET.log >> run.sql

echo "Would you like to create new user for connector operations [y/n]: \c"
read -r NEWUSER

if echo "$NEWUSER" | grep -qE "^(yes|y)"
then
 NEWUSER=Y 
 echo "Are you running this script with EBS target 12.1.x [y/n]: \c"
 read -r EBS121X

 if echo "$EBS121X" | grep -qE "^(yes|y)"
 then
  EBS121X=Y 
 elif echo "$EBS121X" | grep -qE "^(no|n)"
 then
  EBS121X=N 
 else
   echo "Invalid Option"
   exit
 fi
elif echo "$NEWUSER" | grep -qE "^(no|n)"
then
 NEWUSER=N 
else
  echo "Invalid Option"
  exit
fi


# ---- Connecting to DataBase through APPS user----
{
  echo prompt Connecting to APPS;
  echo connect apps@"$Databasename";
  # ---- Creating packages ----
  echo @OIM_TYPES.pck;
  echo @OIM_FND_GLOBAL.pck;
  echo @OIM_EBSHRMS_SCHEMA_PKG.pck;
  echo @OIM_EMPLOYEE_WRAPPER.pck;
} >> run.sql

if echo "$NEWUSER" | grep -qE "^(Y)"
then
echo @OIM_EMPLOYEE_ADDRESS_WRAPPER.pck >> run.sql
else
echo @OIM_EMPLOYEE_ADDRESS_WRAPPER_APPS.pck >> run.sql
fi

echo prompt Disconnecting APPS >> run.sql
echo disconn >> run.sql
# --- If user wants to create new user ---------------
if echo "$NEWUSER" | grep -qE "^(Y)"
then
# ---- Connecting to DataBase through System user----
{
  echo prompt Connecting to "$Systemuser";
  echo connect "$Systemuser"@"$Databasename";
  # ---- Creating the DataBase User---
  echo @OimHRMSUser.sql;
} >> run.sql

if echo "$EBS121X" | grep -qE "^(Y)"
then
 # ---- Executing grant on procedures/packages and Tables----
 echo @OimHRMSUserGrants.sql >> run.sql
fi

{
  echo @OimHRMSUserAcl.sql;
  echo prompt Disconnecting "$Systemuser";
  echo disconn;
} >> run.sql


if echo "$EBS121X" | grep -qE "^(N)"
then
  {
    # ---- Connecting to DataBase through APPS user----
    echo prompt Connecting to APPS;
    echo connect apps@"$Databasename";
    # ---- Executing AD_ZD.grant_privs on procedures/packages and Tables----
    echo @OimHRMSUserAD_ZDGrants.sql;
    echo prompt Disconnecting APPS;
    echo disconn;
  } >> run.sql

fi

{
   # ---- Creating synonym of procedures/packages and Tables----
  echo @OimHRMSAppstablesSynonyms.sql;

  # ---- Creating synonym of procedures/packages Using previously created OimUserAppstablesSynonyms----
  echo @OimHRMSUserSynonyms.sql;
  echo @OIM_TYPES.pck;
  echo @OIM_EBSHRMS_SCHEMA_PKG.pck; 
} >> run.sql
 
fi
{
  echo SPOOL OFF;
  echo EXIT;
} >> run.sql

"$ORACLE_HOME"/bin/sqlplus /nolog @run.sql
rm -f  run.sql
