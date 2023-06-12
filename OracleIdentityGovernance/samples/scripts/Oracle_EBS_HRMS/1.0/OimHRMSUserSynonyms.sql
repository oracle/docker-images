-- Copyright (c) 2023 Oracle and/or its affiliates.
-- 
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
-- 
--  Author: OIG Development
-- 
--  Description: Script file for CREATING synonym of procedures/packages. 
--  Using previously created OimHRMSAppstablesSynonyms for HRF-OIM database USER
--  
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

prompt Connecting &USERNAME;
accept Databasename prompt"Enter the name of the database ::";
connect &USERNAME/&USERPWD@&Databasename;

prompt create or replace  synonym OIM_EMPLOYEE_WRAPPER for APPS.OIM_EMPLOYEE_WRAPPER;
create or replace  synonym OIM_EMPLOYEE_WRAPPER for APPS.OIM_EMPLOYEE_WRAPPER;

prompt create or replace  synonym OIM_EMPLOYEE_ADDRESS_WRAPPER for APPS.OIM_EMPLOYEE_ADDRESS_WRAPPER;
create or replace  synonym OIM_EMPLOYEE_ADDRESS_WRAPPER for APPS.OIM_EMPLOYEE_ADDRESS_WRAPPER;

prompt create or replace synonym OIM_FND_GLOBAL for APPS.OIM_FND_GLOBAL;
create or replace synonym OIM_FND_GLOBAL for APPS.OIM_FND_GLOBAL;

