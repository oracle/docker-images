-- Copyright (c) 2023 Oracle and/or its affiliates.
-- 
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
-- 
--  Author: OIG Development
-- 
--  Description: Script file for EBS UM 
--  
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

create or replace package OIM_EBSUM_SCHEMA_PKG is
    ----------------------------------------------------------------------
    --
    -- Generates schema for Connector
    -- Schema includes supported object classes and attribute information for object classes
    procedure get_schema(
        schemaout OUT schemalist
    );

end OIM_EBSUM_SCHEMA_PKG;

/

create or replace PACKAGE BODY OIM_EBSUM_SCHEMA_PKG AS
   -----------------------------------------------------------------------
   -------------------Schema Declaration----------------------------------
   ------- Add the columns that need to be extended here
   ------- For adding the attributes one need to follow the steps
   -------  1. Add attr.extend  - For every attribute before addition of it to schema
   -------  2. attr (order_no) := attributeinfo(Attr_Name,Attr_Type,creatable,updatable,required,readable) 
               ------Add the attribute info for that extending attribute 
               ------ order_no - the order of the attribute. please dont skip the order
               ------ Attr_Name - the name of the attribute
               ------ Attr_Type - the sql type of the attribute
               ------ creatable,updatable,required,readable - are properties of the attribute. 1 represents true and
               ------ 0 represent false

    procedure get_schema(schemaout OUT schemalist) 
    AS
        attr attributelist;
        BEGIN
        schemaout := schemalist();
        attr := attributelist();
        attr.extend(20); --initialize
        attr (1) := attributeinfo('USER_NAME','varchar2',1,1,1,1);
        attr (2) := attributeinfo('OWNER','varchar2',1,1,0,0);
        attr (3) := attributeinfo('PASSWORD','varchar2',1,1,0,1); 
        attr (4) := attributeinfo('SESSION_NUMBER','varchar2',1,1,0,1);
        attr (5) := attributeinfo('START_DATE','date',1,1,1,1);
        attr (6) := attributeinfo('END_DATE','date',1,1,0,1);
        attr (7) := attributeinfo('DESCRIPTION','varchar2',1,1,0,1);
        attr (8) := attributeinfo('EMAIL_ADDRESS','varchar',1,1,0,1);
        attr (9) := attributeinfo('USER_ID','NUMBER',0,0,1,1);
        attr (10) := attributeinfo('CUSTOMER_ID','VARCHAR',1,1,0,1);
        attr (11) := attributeinfo('SUPPLIER_ID','NUMBER',1,1,0,1);
        attr (12) := attributeinfo('EMPLOYEE_ID','VARCHAR',1,1,0,1);
        attr (13) := attributeinfo('FAX','varchar',1,1,0,1);
        attr (14) := attributeinfo('DATE_UPDATED','date',1,1,0,1);
        attr (15) := attributeinfo('PASSWORD_LIFESPAN','varchar',1,1,0,1);
        attr (16) := attributeinfo('PASSWORD_EXP_TYPE','varchar',1,1,0,1);
        attr (17) := attributeinfo('PARTY_TYPE','varchar',1,1,0,1);
        attr (18) := attributeinfo('PARTY_ID','varchar',1,1,0,1);
        attr (19) := attributeinfo('SUPPLIER_NAME','varchar',1,1,0,1);
        attr (20) := attributeinfo('SUPPLIER_PARTY_ID','varchar',1,1,0,1);
        attr.extend;
        attr (21) := attributeinfo('PARTY_FIRST_NAME','varchar',1,1,0,1);
        attr.extend;
        attr (22) := attributeinfo('PARTY_LAST_NAME','varchar',1,1,0,1);
        attr.extend;
        attr (23) := attributeinfo('USER_GUID','raw',1,1,0,1);
        schemaout.extend;
        schemaout( 1 ) := schema_object('__ACCOUNT__',attr);
    
        attr := attributelist();
        attr.extend(10);
        attr (1) := attributeinfo('RESPONSIBILITY_ID','varchar',1,1,1,1);
        attr (2) := attributeinfo('SECURITY_GROUP_ID','varchar',1,1,1,1);
        attr (3) := attributeinfo('RESP_DESCRIPTION','varchar',1,1,0,1);
        attr (4) := attributeinfo('RESP_START_DATE','date',1,1,1,1);
        attr (5) := attributeinfo('RESP_END_DATE','date',1,1,1,1);
        attr (6) := attributeinfo('RESPONSIBILITY_APP_ID','varchar',1,1,1,1);

        schemaout.extend;
        schemaout( 2 ) := schema_object('__RESPONSIBILITY__',attr);


        attr := attributelist();
        attr.extend(5);
        attr (1) := attributeinfo('ROLE_ID','varchar',1,1,1,1);
        attr (2) := attributeinfo('ROLE_START_DATE','date',1,1,1,1);
        attr (3) := attributeinfo('EXPIRATION_DATE','date',1,1,1,1);
        attr (4) := attributeinfo('ROLE_APP_ID','varchar',1,1,1,1);
        
        schemaout.extend;
        schemaout( 3 ) := schema_object('__ROLE__',attr);
    
    
    END get_schema;

end OIM_EBSUM_SCHEMA_PKG;

/
