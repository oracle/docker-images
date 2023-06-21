-- Copyright (c) 2023 Oracle and/or its affiliates.
-- 
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
-- 
--  Author: OIG Development
-- 
--  Description: Script file for EXECUTE Grant on procedures/packages and Tables required for HRMS
--  
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

---- EXECUTE Grant on procedures/packages required for OIM database USER ----

prompt exec AD_ZD.grant_privs('EXECUTE','HR_EMPLOYEE_API','&USERNAME');
exec AD_ZD.grant_privs('EXECUTE','HR_EMPLOYEE_API','&USERNAME');

prompt exec AD_ZD.grant_privs('EXECUTE','HR_PERSON_API','&USERNAME');
exec AD_ZD.grant_privs('EXECUTE','HR_PERSON_API','&USERNAME');

prompt exec AD_ZD.grant_privs('EXECUTE','HR_CHANGE_START_DATE_API','&USERNAME');
exec AD_ZD.grant_privs('EXECUTE','HR_CHANGE_START_DATE_API','&USERNAME');

prompt exec AD_ZD.grant_privs('EXECUTE','HR_PERSON_ADDRESS_API','&USERNAME'); 
exec AD_ZD.grant_privs('EXECUTE','HR_PERSON_ADDRESS_API','&USERNAME');

prompt exec AD_ZD.grant_privs('EXECUTE','HR_PERSON_ADDRESS_BK1','&USERNAME'); 
exec AD_ZD.grant_privs('EXECUTE','HR_PERSON_ADDRESS_BK1','&USERNAME');

prompt exec AD_ZD.grant_privs('EXECUTE','HR_API','&USERNAME'); 
exec AD_ZD.grant_privs('EXECUTE','HR_API','&USERNAME');

prompt exec AD_ZD.grant_privs('EXECUTE','HR_CONTINGENT_WORKER_API','&USERNAME'); 
exec AD_ZD.grant_privs('EXECUTE','HR_CONTINGENT_WORKER_API','&USERNAME');

prompt exec AD_ZD.grant_privs('EXECUTE','HR_ASSIGNMENT_API','&USERNAME'); 
exec AD_ZD.grant_privs('EXECUTE','HR_ASSIGNMENT_API','&USERNAME');

prompt exec AD_ZD.grant_privs('EXECUTE','FND_GLOBAL','&USERNAME');
exec AD_ZD.grant_privs('EXECUTE','FND_GLOBAL','&USERNAME');

---- SELECT Grant on tables required for OIM database USER ----

prompt exec AD_ZD.grant_privs('SELECT','PER_ALL_ASSIGNMENTS_F','&USERNAME');
exec AD_ZD.grant_privs('SELECT','PER_ALL_ASSIGNMENTS_F','&USERNAME');
prompt exec AD_ZD.grant_privs('UPDATE','PER_ALL_ASSIGNMENTS_F','&USERNAME');
exec AD_ZD.grant_privs('UPDATE','PER_ALL_ASSIGNMENTS_F','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','PER_PEOPLE_F','&USERNAME');
exec AD_ZD.grant_privs('SELECT','PER_PEOPLE_F','&USERNAME');
prompt exec AD_ZD.grant_privs('UPDATE','PER_PEOPLE_F','&USERNAME');
exec AD_ZD.grant_privs('UPDATE','PER_PEOPLE_F','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','PER_PERSON_TYPES','&USERNAME');
exec AD_ZD.grant_privs('SELECT','PER_PERSON_TYPES','&USERNAME');
prompt exec AD_ZD.grant_privs('UPDATE','PER_PERSON_TYPES','&USERNAME');
exec AD_ZD.grant_privs('UPDATE','PER_PERSON_TYPES','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','PER_PERIODS_OF_SERVICE','&USERNAME');
exec AD_ZD.grant_privs('SELECT','PER_PERIODS_OF_SERVICE','&USERNAME');
prompt exec AD_ZD.grant_privs('UPDATE','PER_PERIODS_OF_SERVICE','&USERNAME');
exec AD_ZD.grant_privs('UPDATE','PER_PERIODS_OF_SERVICE','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','PER_PERIODS_OF_PLACEMENT','&USERNAME');
exec AD_ZD.grant_privs('SELECT','PER_PERIODS_OF_PLACEMENT','&USERNAME');
prompt exec AD_ZD.grant_privs('UPDATE','PER_PERIODS_OF_PLACEMENT','&USERNAME');
exec AD_ZD.grant_privs('UPDATE','PER_PERIODS_OF_PLACEMENT','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','PER_ADDRESSES','&USERNAME');
exec AD_ZD.grant_privs('SELECT','PER_ADDRESSES','&USERNAME');
prompt exec AD_ZD.grant_privs('UPDATE','PER_ADDRESSES','&USERNAME');
exec AD_ZD.grant_privs('UPDATE','PER_ADDRESSES','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','PER_PERSON_TYPE_USAGES_F','&USERNAME');
exec AD_ZD.grant_privs('SELECT','PER_PERSON_TYPE_USAGES_F','&USERNAME');
prompt exec AD_ZD.grant_privs('UPDATE','PER_PERSON_TYPE_USAGES_F','&USERNAME');
exec AD_ZD.grant_privs('UPDATE','PER_PERSON_TYPE_USAGES_F','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','PER_ALL_PEOPLE_F','&USERNAME');
exec AD_ZD.grant_privs('SELECT','PER_ALL_PEOPLE_F','&USERNAME');
prompt exec AD_ZD.grant_privs('UPDATE','PER_ALL_PEOPLE_F','&USERNAME');
exec AD_ZD.grant_privs('UPDATE','PER_ALL_PEOPLE_F','&USERNAME');


-- Grant execute privileges to the wrapper packages created in APPS schema

prompt exec AD_ZD.grant_privs('EXECUTE','OIM_EMPLOYEE_WRAPPER','&USERNAME'); 
exec AD_ZD.grant_privs('EXECUTE','OIM_EMPLOYEE_WRAPPER','&USERNAME');

prompt exec AD_ZD.grant_privs('EXECUTE','OIM_EMPLOYEE_ADDRESS_WRAPPER','&USERNAME'); 
exec AD_ZD.grant_privs('EXECUTE','OIM_EMPLOYEE_ADDRESS_WRAPPER','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','HZ_PARTIES','&USERNAME'); 
exec AD_ZD.grant_privs('SELECT','HZ_PARTIES','&USERNAME'); 
prompt exec AD_ZD.grant_privs('UPDATE','HZ_PARTIES','&USERNAME'); 
exec AD_ZD.grant_privs('UPDATE','HZ_PARTIES','&USERNAME'); 

prompt exec AD_ZD.grant_privs('SELECT','PER_JOBS','&USERNAME'); 
exec AD_ZD.grant_privs('SELECT','PER_JOBS','&USERNAME'); 
prompt exec AD_ZD.grant_privs('UPDATE','PER_JOBS','&USERNAME'); 
exec AD_ZD.grant_privs('UPDATE','PER_JOBS','&USERNAME'); 

prompt exec AD_ZD.grant_privs('SELECT','PER_GRADES','&USERNAME'); 
exec AD_ZD.grant_privs('SELECT','PER_GRADES','&USERNAME'); 
prompt exec AD_ZD.grant_privs('UPDATE','PER_GRADES','&USERNAME'); 
exec AD_ZD.grant_privs('UPDATE','PER_GRADES','&USERNAME'); 

prompt exec AD_ZD.grant_privs('SELECT','HR_ALL_ORGANIZATION_UNITS','&USERNAME'); 
exec AD_ZD.grant_privs('SELECT','HR_ALL_ORGANIZATION_UNITS','&USERNAME'); 
prompt exec AD_ZD.grant_privs('UPDATE','HR_ALL_ORGANIZATION_UNITS','&USERNAME'); 
exec AD_ZD.grant_privs('UPDATE','HR_ALL_ORGANIZATION_UNITS','&USERNAME'); 

prompt exec AD_ZD.grant_privs('SELECT','PER_VALID_GRADES','&USERNAME'); 
exec AD_ZD.grant_privs('SELECT','PER_VALID_GRADES','&USERNAME'); 
prompt exec AD_ZD.grant_privs('UPDATE','PER_VALID_GRADES','&USERNAME'); 
exec AD_ZD.grant_privs('UPDATE','PER_VALID_GRADES','&USERNAME'); 

prompt exec AD_ZD.grant_privs('SELECT','FND_LOOKUP_VALUES_VL','&USERNAME'); 
exec AD_ZD.grant_privs('SELECT','FND_LOOKUP_VALUES_VL','&USERNAME'); 
prompt exec AD_ZD.grant_privs('UPDATE','FND_LOOKUP_VALUES_VL','&USERNAME'); 
exec AD_ZD.grant_privs('UPDATE','FND_LOOKUP_VALUES_VL','&USERNAME'); 

prompt exec AD_ZD.grant_privs('EXECUTE','OIM_FND_GLOBAL','&USERNAME'); 
exec AD_ZD.grant_privs('EXECUTE','OIM_FND_GLOBAL','&USERNAME');
