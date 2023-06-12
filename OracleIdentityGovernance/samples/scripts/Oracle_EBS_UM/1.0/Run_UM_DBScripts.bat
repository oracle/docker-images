REM Copyright (c) 2023 Oracle and/or its affiliates.
REM 
REM Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
REM 
REM  Author: OIG Development
REM 
REM  Description:  Script file for Creating a service account in EBS target for UM 
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
ECHO SPOOL OIM_APPS_USER.log >> run.sql

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

:continue
REM ---- Connecting to DataBase through APPS user----
ECHO prompt Connecting to APPS >> run.sql
ECHO connect apps@%Databasename% >> run.sql


REM ---- Creating packages ----
ECHO @OIM_TYPES.pck >> run.sql
ECHO @OIM_EBSUM_SCHEMA_PKG.pck >> run.sql
ECHO @OIM_FND_GLOBAL.pck >> run.sql
ECHO @OIM_FND_USER_TCA_PKG.pck >> run.sql
ECHO @GET_LAST_UPDATE_DATE_FUNCTION.pck >> run.sql

ECHO prompt Disconnecting APPS >> run.sql
ECHO disconn >> run.sql

REM ---- Connecting to DataBase through System user----
ECHO prompt Connecting to %Systemuser% >> run.sql
ECHO connect %Systemuser%@%Databasename% >>run.sql

REM ---- Creating the DataBase User----
ECHO @OimUser.sql >> run.sql

IF /I "%EBS121X%" == "Y" (
    REM ---- Executing Grant on procedures/packages and Tables----
    ECHO @OimUserGrants.sql >> run.sql
)

ECHO prompt Disconnecting %Systemuser% >> run.sql
ECHO disconn >> run.sql

IF /I "%EBS121X%" == "N" (
    REM ---- Connecting to DataBase through APPS user----
    ECHO prompt Connecting to APPS >> run.sql
    ECHO connect apps@%Databasename% >> run.sql

    REM ---- Executing AD_ZD.grant_privs on procedures/packages and Tables----
    ECHO @OimUserAD_ZDGrants.sql >> run.sql

    ECHO prompt Disconnecting APPS >> run.sql
    ECHO disconn >> run.sql
)

REM ---- Creating synonym of procedures/packages and Tables----
ECHO @OimUserAppstablesSynonyms.sql >> run.sql

REM ---- Creating synonym of procedures/packages Using previously created OimUserAppstablesSynonyms----
ECHO @OimUserSynonyms.sql >> run.sql
ECHO @OIM_TYPES.pck >> run.sql
ECHO @OIM_EBSUM_SCHEMA_PKG.pck >> run.sql
ECHO @GET_LAST_UPDATE_DATE_FUNCTION.pck >> run.sql


ECHO SPOOL OFF >> run.sql
ECHO EXIT >> run.sql

%ORACLE_HOME%\bin\sqlplus /nolog @run.sql
del run.sql
:end
