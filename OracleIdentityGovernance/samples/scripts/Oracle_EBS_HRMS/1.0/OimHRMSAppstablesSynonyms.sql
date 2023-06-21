-- Copyright (c) 2023 Oracle and/or its affiliates.
-- 
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
-- 
--  Author: OIG Development
-- 
--  Description: Script file for CREATING synonym of procedures/packages and Tables required for HRMS
--  
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

prompt Connecting &USERNAME;
accept Databasename prompt"Enter the name of the database ::";
connect &USERNAME/&USERPWD@&Databasename;

prompt create or replace  synonym PER_PEOPLE_F for APPS.PER_PEOPLE_F;
create or replace  synonym PER_PEOPLE_F for APPS.PER_PEOPLE_F;

prompt create or replace  synonym PER_ALL_ASSIGNMENTS_F  for APPS.PER_ALL_ASSIGNMENTS_F;
create or replace  synonym PER_ALL_ASSIGNMENTS_F for APPS.PER_ALL_ASSIGNMENTS_F;

prompt create or replace  synonym PER_PERIODS_OF_SERVICE for APPS.PER_PERIODS_OF_SERVICE;
create or replace  synonym PER_PERIODS_OF_SERVICE for APPS.PER_PERIODS_OF_SERVICE;

prompt create or replace  synonym PER_PERIODS_OF_PLACEMENT for APPS.PER_PERIODS_OF_PLACEMENT;
create or replace  synonym PER_PERIODS_OF_PLACEMENT for APPS.PER_PERIODS_OF_PLACEMENT;

prompt create or replace  synonym HR_EMPLOYEE_API for APPS.HR_EMPLOYEE_API;
create or replace  synonym HR_EMPLOYEE_API for APPS.HR_EMPLOYEE_API;

prompt create or replace  synonym HR_PERSON_API for APPS.HR_PERSON_API;
create or replace  synonym HR_PERSON_API for APPS.HR_PERSON_API;

prompt create or replace  synonym HR_CHANGE_START_DATE_API for APPS.HR_CHANGE_START_DATE_API;
create or replace  synonym HR_CHANGE_START_DATE_API for APPS.HR_CHANGE_START_DATE_API;

prompt create or replace  synonym PER_ADDRESSES for APPS.PER_ADDRESSES;
create or replace  synonym PER_ADDRESSES for APPS.PER_ADDRESSES;

prompt create or replace  synonym PER_PERSON_TYPE_USAGES_F for APPS.PER_PERSON_TYPE_USAGES_F;
create or replace  synonym PER_PERSON_TYPE_USAGES_F for APPS.PER_PERSON_TYPE_USAGES_F;


prompt create or replace  synonym PER_ALL_PEOPLE_F for APPS.PER_ALL_PEOPLE_F;
create or replace  synonym PER_ALL_PEOPLE_F for APPS.PER_ALL_PEOPLE_F;

prompt create or replace  synonym PER_JOBS for APPS.PER_JOBS;
create or replace  synonym PER_JOBS for APPS.PER_JOBS;

prompt create or replace  synonym PER_GRADES for APPS.PER_GRADES;
create or replace  synonym PER_GRADES for APPS.PER_GRADES;

prompt create or replace  synonym HR_ALL_ORGANIZATION_UNITS for APPS.HR_ALL_ORGANIZATION_UNITS;
create or replace  synonym HR_ALL_ORGANIZATION_UNITS for APPS.HR_ALL_ORGANIZATION_UNITS;

prompt create or replace  synonym HR_PERSON_ADDRESS_API for APPS.HR_PERSON_ADDRESS_API;
create or replace  synonym HR_PERSON_ADDRESS_API for APPS.HR_PERSON_ADDRESS_API;

prompt create or replace  synonym HR_CONTINGENT_WORKER_API for APPS.HR_CONTINGENT_WORKER_API;
create or replace  synonym HR_CONTINGENT_WORKER_API for APPS.HR_CONTINGENT_WORKER_API;

prompt create or replace  synonym HR_ASSIGNMENT_API for APPS.HR_ASSIGNMENT_API;
create or replace  synonym HR_ASSIGNMENT_API for APPS.HR_ASSIGNMENT_API;

prompt create or replace  synonym HR_PERSON_ADDRESS_BK1 for APPS.HR_PERSON_ADDRESS_BK1;
create or replace  synonym HR_PERSON_ADDRESS_BK1 for APPS.HR_PERSON_ADDRESS_BK1;

prompt create or replace  synonym hr_api for APPS.hr_api;
create or replace  synonym hr_api for APPS.hr_api;


prompt create or replace  synonym HZ_PARTIES for APPS.HZ_PARTIES;
create or replace  synonym HZ_PARTIES for APPS.HZ_PARTIES;

prompt create or replace  synonym PER_PERSON_TYPES for APPS.PER_PERSON_TYPES;
create or replace  synonym PER_PERSON_TYPES for APPS.PER_PERSON_TYPES;

prompt create or replace  synonym PER_VALID_GRADES for APPS.PER_VALID_GRADES;
create or replace  synonym PER_VALID_GRADES for APPS.PER_VALID_GRADES;

prompt create or replace  synonym FND_LOOKUP_VALUES_VL for APPS.FND_LOOKUP_VALUES_VL;
create or replace  synonym FND_LOOKUP_VALUES_VL for APPS.FND_LOOKUP_VALUES_VL;

