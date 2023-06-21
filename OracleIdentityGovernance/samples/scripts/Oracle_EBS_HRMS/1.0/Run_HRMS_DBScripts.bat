
REM Copyright (c) 2023 Oracle and/or its affiliates.
REM 
REM Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
REM 
REM  Author: OIG Development
REM 
REM  Description: Script file for Creating a service account in EBS target For HRMS
REM 
REM 
REM  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

echo off
if exist run.sql del run.sql

if "%ORACLE_HOME%"=="" (
SET /p ORACLE_HOME=Enter the ORACLE_HOME ::
) else (
ECHO ORACLE_HOME is ::%ORACLE_HOME%
)

SET /p Systemuser=Enter the System User name ::

SET /p Databasename=Enter the name of the database ::

REM ---- Create Log file ----
ECHO SPOOL OIM_APPS_HRMS_TARGET.log >> run.sql
SET /p NEWUSER=Would you like to create new user for connector operations [y/n] :: 
IF /I "%NEWUSER%" == "yes" (
goto :yes
) else IF /I "%NEWUSER%" == "y" (
goto :yes
) else IF /I "%NEWUSER%" == "no" (
goto :no
) else IF /I "%NEWUSER%" == "n" (
goto :no
) else (
echo "Invalid option"
goto :end
)

:yes
set NEWUSER=Y
SET /p EBS121X=Are you running this script with EBS target 12.1.x [y/n] :: 
IF /I "%EBS121X%" == "yes" (
goto :yesEBS121X
) else IF /I "%EBS121X%" == "y" (
goto :yesEBS121X
) else IF /I "%EBS121X%" == "no" (
goto :noEBS121X
) else IF /I "%EBS121X%" == "n" (
goto :noEBS121X
) else (
echo "Invalid option"
goto :end
)

:yesEBS121X
set EBS121X=Y
goto :continue

:noEBS121X
set EBS121X=N
goto :continue

:no
set NEWUSER=N

:continue
REM ---- Connecting to DataBase through APPS user----
ECHO prompt Connecting to APPS >> run.sql
ECHO connect apps@%Databasename% >> run.sql


REM ---- Creating packages ----
ECHO @OIM_TYPES.pck >> run.sql
ECHO @OIM_FND_GLOBAL.pck >> run.sql
ECHO @OIM_EBSHRMS_SCHEMA_PKG.pck >> run.sql
ECHO @OIM_EMPLOYEE_WRAPPER.pck >> run.sql

IF  "%NEWUSER%" == "Y" (
    ECHO @OIM_EMPLOYEE_ADDRESS_WRAPPER.pck >> run.sql
) else (
    ECHO @OIM_EMPLOYEE_ADDRESS_WRAPPER_APPS.pck >> run.sql
)

ECHO prompt Disconnecting APPS >> run.sql
ECHO disconn >> run.sql

IF /I "%NEWUSER%" == "Y" (
    REM ---- Connecting to DataBase through System user----
    ECHO prompt Connecting to %Systemuser% >> run.sql
    ECHO connect %Systemuser%@%Databasename% >>run.sql
    
    REM ---- Creating the DataBase User----
    ECHO @OimHRMSUser.sql >> run.sql
    
    IF /I "%EBS121X%" == "Y" (
        REM ---- Executing Grant on procedures/packages and Tables----
        ECHO @OimHRMSUserGrants.sql >> run.sql
    )

    ECHO @OimHRMSUserAcl.sql >> run.sql
    
    ECHO prompt Disconnecting %Systemuser% >> run.sql
    ECHO disconn >> run.sql
    
    IF /I "%EBS121X%" == "N" (
        REM ---- Connecting to DataBase through APPS user----
        ECHO prompt Connecting to APPS >> run.sql
        ECHO connect apps@%Databasename% >> run.sql

        REM ---- Executing AD_ZD.grant_privs on procedures/packages and Tables----
        ECHO @OimHRMSUserAD_ZDGrants.sql >> run.sql

        ECHO prompt Disconnecting APPS >> run.sql
        ECHO disconn >> run.sql
    )

    REM ---- Creating synonym of procedures/packages and Tables----
    ECHO @OimHRMSAppstablesSynonyms.sql >> run.sql
    
    REM ---- Creating synonym of procedures/packages Using previously created OimUserAppstablesSynonyms----
    ECHO @OimHRMSUserSynonyms.sql >> run.sql
    ECHO @OIM_TYPES.pck >> run.sql
    ECHO @OIM_EBSHRMS_SCHEMA_PKG.pck >> run.sql
)

ECHO SPOOL OFF >> run.sql
ECHO EXIT >> run.sql

%ORACLE_HOME%\bin\sqlplus /nolog @run.sql
del run.sql
:end
