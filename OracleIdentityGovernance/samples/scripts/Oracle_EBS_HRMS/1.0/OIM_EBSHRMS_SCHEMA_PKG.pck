-- Copyright (c) 2023 Oracle and/or its affiliates.
-- 
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
-- 
--  Author: OIG Development
-- 
--  Description: Script file for CREATING synonym of procedures/packages and Tables required for HRMS
--  
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

create or replace PACKAGE OIM_EBSHRMS_SCHEMA_PKG AS

 PROCEDURE get_schema( schemaout OUT schemalist);

 END OIM_EBSHRMS_SCHEMA_PKG;

 /

create or replace PACKAGE BODY OIM_EBSHRMS_SCHEMA_PKG AS

procedure get_schema(
 schemaout OUT schemalist
 ) AS
 attr attributelist;
  BEGIN
    schemaout := schemalist();
    schemaout.extend(1);
    attr := attributelist();
    attr.extend (50);
    attr (1) := attributeinfo('HIRE_DATE','date',1,1,0,1);
    attr (2) := attributeinfo('BUSINESS_GROUP_ID','varchar2',1,1,0,1);
    attr (3) := attributeinfo('LAST_NAME','varchar2',1,1,1,1);
    attr (4) := attributeinfo('FIRST_NAME','varchar2',1,1,1,1);
    attr (5) := attributeinfo('SEX','varchar2',1,1,0,1);
    attr (6) := attributeinfo('PERSON_TYPE_ID','varchar2',1,1,0,1);
    attr (7) := attributeinfo('EMPLOYEE_NUMBER','varchar2',1,1,0,1);
    attr (8) := attributeinfo('PERSON_ID','varchar2',1,1,0,1);
    attr (9) := attributeinfo('TITLE','varchar2',1,1,0,1);
    attr (10) := attributeinfo('EMAIL_ADDRESS','varchar2',1,1,0,1);
    attr (11) := attributeinfo('MARITAL_STATUS','varchar2',1,1,0,1);
    attr (12) := attributeinfo('NATIONALITY','varchar2',1,1,0,1);
    attr (13) := attributeinfo('NATIONAL_IDENTIFIER','varchar2',1,1,0,1);
    attr (14) := attributeinfo('DATE_OF_BIRTH','date',1,1,0,1);
    attr (15) := attributeinfo('TOWN_OF_BIRTH','varchar2',1,1,0,1);
    attr (16) := attributeinfo('REGION_OF_BIRTH','varchar2',1,1,0,1);
    attr (17) := attributeinfo('COUNTRY_OF_BIRTH','varchar2',1,1,0,1);
    attr (18) := attributeinfo('USER_PERSON_TYPE','varchar2',1,1,0,1);
    attr (19) := attributeinfo('EFFECTIVE_START_DATE','date',1,1,0,1);
    attr (20) := attributeinfo('ACTUAL_TERMINATION_DATE','date',1,1,0,1);
    attr (21) := attributeinfo('SUPERVISOR_ID','varchar2',1,1,0,1);
    attr (22) := attributeinfo('SUPERVISOR_NAME','varchar2',0,0,0,1);
    attr (23) := attributeinfo('JOB','varchar2',1,1,0,1);
    attr (24) := attributeinfo('GRADE','varchar2',1,1,0,1);
    attr (25) := attributeinfo('DEPARTMENT','varchar2',1,1,0,1);
    attr (26) := attributeinfo('PERSON_UPDATED_DATE','date',1,1,0,1);
    attr (27) := attributeinfo('ASSIGNMENT_UPDATED_DATE','date',1,1,0,1);

    schemaout( 1 ) := schema_object('__PERSON__',attr);

    attr := attributelist();
    attr.extend;
    attr (1) := attributeinfo('ADDRESS_ID','number',1,0,0,1);
    attr.extend;
    attr (2) := attributeinfo('PRIMARY_FLAG','varchar',1,1,0,1);
    attr.extend;
    attr (3) := attributeinfo('STYLE','varchar',1,1,0,1);
    attr.extend;
    attr (4) := attributeinfo('DATE_FROM','date',1,1,0,1);
    attr.extend;
    attr (5) := attributeinfo('ADDRESS_LINE1','varchar',1,1,0,1);
    attr.extend;
    attr (6) := attributeinfo('ADDRESS_LINE2','varchar',1,1,0,1);
    attr.extend;
    attr (7) := attributeinfo('ADDRESS_LINE3','varchar',1,1,0,1);
    attr.extend;
    attr (8) := attributeinfo('TOWN_OR_CITY','varchar',1,1,0,1);
    attr.extend;
    attr (9) := attributeinfo('REGION_1','varchar',1,1,0,1);
    attr.extend;
    attr (10) := attributeinfo('REGION_2','varchar',1,1,0,1);
    attr.extend;
    attr (11) := attributeinfo('REGION_3','varchar',1,1,0,1);
    attr.extend;
    attr (12) := attributeinfo('POSTAL_CODE','varchar',1,1,0,1);
    attr.extend;
    attr (13) := attributeinfo('COUNTRY','varchar',1,1,0,1);
    attr.extend;
    attr (14) := attributeinfo('DATE_TO','date',1,1,0,1);
    attr.extend;
    attr (15) := attributeinfo('ADDRESS_TYPE','varchar',1,1,0,1);
    attr.extend;

    schemaout.extend;
    schemaout( 2 ) := schema_object('__ADDRESS__',attr);


    attr := attributelist();
    attr.extend;
    attr (1) := attributeinfo('ASSIGNMENT_ID','number',1,0,0,1);
    attr.extend;
    attr (2) := attributeinfo('ASG_EFFECTIVE_START_DATE','date',1,0,0,1);
    attr.extend;
    attr (3) := attributeinfo('CHANGE_REASON','varchar',1,1,0,1);
    attr.extend;
    attr (4) := attributeinfo('ORGANIZATION_ID','number',1,1,0,1);
    attr.extend;
    attr (5) := attributeinfo('JOB_ID','number',1,1,0,1);
    attr.extend;
    attr (6) := attributeinfo('GRADE_ID','number',1,1,0,1);
    attr.extend;
    attr (7) := attributeinfo('SUPERVISOR_ID','number',1,1,0,1);
    attr.extend;

    schemaout.extend;
    schemaout( 3 ) := schema_object('__ASSIGNMENT__',attr);

END get_schema;

END OIM_EBSHRMS_SCHEMA_PKG;
/
