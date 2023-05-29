#!/bin/sh
# --------------------------------------------------------------------
#    Script file for Creating a service account in EBS target For HRMS
# --------------------------------------------------------------------

if [ -f run.sql ]
then
rm -f run.sql
fi

if [ -f $ORACLE_HOME ]
then
echo "Enter the ORACLE_HOME ::"
read orahome
ORACLE_HOME=$orahome
else
echo "ORACLE_HOME is ::"
echo $ORACLE_HOME
fi

export ORACLE_HOME

echo Enter the System User Name ::
read Systemuser

echo Enter the name of the database ::
read Databasename

# ---- User Input to choose Connector  ----

# ---- Create Log file ----
echo SPOOL OIM_APPS_HRMS_TARGET.log >> run.sql

read -p "Would you like to create new user for connector operations [y/n]:" NEWUSER
if [[ $NEWUSER =~ ^(yes|y) ]] 
then
 NEWUSER=Y 
 read -p "Are you running this script with EBS target 12.1.x [y/n]:" EBS121X

 if [[ $EBS121X =~ ^(yes|y) ]] 
 then
  EBS121X=Y 
 elif [[ $EBS121X =~ ^(no|n) ]] 
 then
  EBS121X=N 
 else
   echo "Invalid Option"
   exit
 fi
elif [[ $NEWUSER =~ ^(no|n) ]] 
then
 NEWUSER=N 
else
  echo "Invalid Option"
  exit
fi


# ---- Connecting to DataBase through APPS user----
echo prompt Connecting to APPS >> run.sql
echo connect apps@$Databasename >> run.sql

# ---- Creating packages ----
echo @OIM_TYPES.pck >> run.sql
echo @OIM_FND_GLOBAL.pck >> run.sql
echo @OIM_EBSHRMS_SCHEMA_PKG.pck >> run.sql
echo @OIM_EMPLOYEE_WRAPPER.pck >> run.sql
if [[ $NEWUSER =~ ^(Y) ]] 
then
echo @OIM_EMPLOYEE_ADDRESS_WRAPPER.pck >> run.sql
else
echo @OIM_EMPLOYEE_ADDRESS_WRAPPER_APPS.pck >> run.sql
fi

echo prompt Disconnecting APPS >> run.sql
echo disconn >> run.sql
# --- If user wants to create new user ---------------
if [[ $NEWUSER =~ ^(Y) ]] 
then
# ---- Connecting to DataBase through System user----
echo prompt Connecting to $Systemuser >> run.sql
echo connect $Systemuser@$Databasename >>run.sql

# ---- Creating the DataBase User---
echo @OimHRMSUser.sql >> run.sql

if [[ $EBS121X =~ ^(Y) ]] 
then
 # ---- Executing grant on procedures/packages and Tables----
 echo @OimHRMSUserGrants.sql >> run.sql
fi

echo @OimHRMSUserAcl.sql >> run.sql

echo prompt Disconnecting $Systemuser >> run.sql
echo disconn >> run.sql

if [[ $EBS121X =~ ^(N) ]] 
then
 # ---- Connecting to DataBase through APPS user----
 echo prompt Connecting to APPS >> run.sql
 echo connect apps@$Databasename >> run.sql

 # ---- Executing AD_ZD.grant_privs on procedures/packages and Tables----
 echo @OimHRMSUserAD_ZDGrants.sql >> run.sql

 echo prompt Disconnecting APPS >> run.sql
 echo disconn >> run.sql
fi

# ---- Creating synonym of procedures/packages and Tables----
echo @OimHRMSAppstablesSynonyms.sql >> run.sql

# ---- Creating synonym of procedures/packages Using previously created OimUserAppstablesSynonyms----
echo @OimHRMSUserSynonyms.sql >> run.sql
echo @OIM_TYPES.pck >> run.sql
echo @OIM_EBSHRMS_SCHEMA_PKG.pck >> run.sql
fi
echo SPOOL OFF >> run.sql
echo EXIT >> run.sql

$ORACLE_HOME/bin/sqlplus /nolog @run.sql
rm -f  run.sql
