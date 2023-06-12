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

prompt grant execute on APPS.HR_EMPLOYEE_API to &USERNAME;
grant execute on APPS.HR_EMPLOYEE_API to &USERNAME;

prompt grant execute on APPS.HR_PERSON_API to &USERNAME;
grant execute on APPS.HR_PERSON_API to &USERNAME;

prompt grant execute on APPS.HR_CHANGE_START_DATE_API to &USERNAME;
grant execute on APPS.HR_CHANGE_START_DATE_API to &USERNAME;

prompt grant execute on APPS.HR_PERSON_ADDRESS_API to &USERNAME; 
grant execute on APPS.HR_PERSON_ADDRESS_API to &USERNAME;

prompt grant execute on APPS.HR_PERSON_ADDRESS_BK1 to &USERNAME; 
grant execute on APPS.HR_PERSON_ADDRESS_BK1 to &USERNAME;

prompt grant execute on APPS.HR_API to &USERNAME; 
grant execute on APPS.HR_API to &USERNAME;

prompt grant execute on APPS.HR_CONTINGENT_WORKER_API to &USERNAME; 
grant execute on APPS.HR_CONTINGENT_WORKER_API to &USERNAME;

prompt grant execute on APPS.HR_ASSIGNMENT_API to &USERNAME; 
grant execute on APPS.HR_ASSIGNMENT_API to &USERNAME;

prompt grant execute on APPS.FND_GLOBAL to &USERNAME;
grant execute on APPS.FND_GLOBAL to &USERNAME;

---- SELECT Grant on tables required for OIM database USER ----

prompt grant select on APPS.PER_ALL_ASSIGNMENTS_F to &USERNAME;
grant select, update on APPS.PER_ALL_ASSIGNMENTS_F to &USERNAME;

prompt grant select on APPS.PER_PEOPLE_F to &USERNAME;
grant select, update on APPS.PER_PEOPLE_F to &USERNAME;

prompt grant select on APPS.PER_PERSON_TYPES to &USERNAME;
grant select, update on APPS.PER_PERSON_TYPES to &USERNAME;

prompt grant select on APPS.PER_PERIODS_OF_SERVICE to &USERNAME;
grant select, update on APPS.PER_PERIODS_OF_SERVICE to &USERNAME;

prompt grant select on APPS.PER_PERIODS_OF_PLACEMENT to &USERNAME;
grant select, update on APPS.PER_PERIODS_OF_PLACEMENT to &USERNAME;

prompt grant select on APPS.PER_ADDRESSES to &USERNAME;
grant select, update on APPS.PER_ADDRESSES to &USERNAME;

prompt grant select on APPS.PER_PERSON_TYPE_USAGES_F to &USERNAME;
grant select, update on APPS.PER_PERSON_TYPE_USAGES_F to &USERNAME;

prompt grant select on APPS.PER_ALL_PEOPLE_F to &USERNAME;
grant select, update on APPS.PER_ALL_PEOPLE_F to &USERNAME;


-- Grant execute privileges to the wrapper packages created in APPS schema

prompt grant execute on APPS.OIM_EMPLOYEE_WRAPPER to &USERNAME; 
grant execute on APPS.OIM_EMPLOYEE_WRAPPER to &USERNAME;

prompt grant execute on APPS.OIM_EMPLOYEE_ADDRESS_WRAPPER to &USERNAME; 
grant execute on APPS.OIM_EMPLOYEE_ADDRESS_WRAPPER to &USERNAME;

prompt grant select, update on APPS.HZ_PARTIES to &USERNAME; 
grant select, update on APPS.HZ_PARTIES to &USERNAME;

prompt grant select, update on APPS.PER_JOBS to &USERNAME; 
grant select, update on APPS.PER_JOBS to &USERNAME;

prompt grant select, update on APPS.PER_GRADES to &USERNAME; 
grant select, update on APPS.PER_GRADES to &USERNAME;

prompt grant select, update on APPS.HR_ALL_ORGANIZATION_UNITS to &USERNAME; 
grant select, update on APPS.HR_ALL_ORGANIZATION_UNITS to &USERNAME;

prompt grant select, update on APPS.PER_VALID_GRADES to &USERNAME; 
grant select, update on APPS.PER_VALID_GRADES to &USERNAME;

prompt grant select, update on APPS.FND_LOOKUP_VALUES_VL to &USERNAME; 
grant select, update on APPS.FND_LOOKUP_VALUES_VL to &USERNAME;

prompt grant execute on APPS.OIM_FND_GLOBAL to &USERNAME; 
grant execute on APPS.OIM_FND_GLOBAL to &USERNAME;
