#!/bin/sh
#
# Copyright (c) 2023 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: OIG Development
#
# Description: Script file for Creating a service account in EBS target for UM
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
ORACLE_HOME="$orahome"
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
echo SPOOL OIM_APPS_USER.log >> run.sql
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

# ---- Connecting to DataBase through APPS user----
{ echo prompt Connecting to APPS; 
  echo connect apps@"$Databasename";
# ---- Creating packages ----
  echo @OIM_TYPES.pck;
  echo @OIM_EBSUM_SCHEMA_PKG.pck;
  echo @OIM_FND_GLOBAL.pck;
  echo @OIM_FND_USER_TCA_PKG.pck;
  echo @GET_LAST_UPDATE_DATE_FUNCTION.pck;

  echo prompt Disconnecting APPS;
  echo disconn;

  # ---- Connecting to DataBase through System user----
  echo prompt Connecting to "$Systemuser";
  echo connect "$Systemuser"@"$Databasename";
  # ---- Creating the DataBase User---
  echo @OimUser.sql;
} >> run.sql


if echo "$EBS121X" | grep -qE "^(Y)"
then
 # ---- Executing grant on procedures/packages and Tables----
 echo @OimUserGrants.sql >> run.sql
fi

echo prompt Disconnecting "$Systemuser" >> run.sql
echo disconn >> run.sql

if echo "$EBS121X" | grep -qE "^(N)"
then
 
 {
  # ---- Connecting to DataBase through APPS user----
  echo prompt Connecting to APPS;
  echo connect apps@"$Databasename";

  # ---- Executing AD_ZD.grant_privs on procedures/packages and Tables----
  echo @OimUserAD_ZDGrants.sql;

  echo prompt Disconnecting APPS;
  echo disconn;
 }  >> run.sql
fi

{
  # ---- Creating synonym of procedures/packages and Tables----
  echo @OimUserAppstablesSynonyms.sql;

  # ---- Creating synonym of procedures/packages Using previously created OimUserAppstablesSynonyms----
  echo @OimUserSynonyms.sql;
  echo @OIM_TYPES.pck;
  echo @OIM_EBSUM_SCHEMA_PKG.pck;
  echo @GET_LAST_UPDATE_DATE_FUNCTION.pck;

  echo SPOOL OFF;
  echo EXIT;
 } >> run.sql

"$ORACLE_HOME"/bin/sqlplus /nolog @run.sql
rm -f  run.sql
