-- Copyright (c) 2023 Oracle and/or its affiliates.
-- 
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
-- 
--  Author: OIG Development
-- 
--  Description: Script file for EBS UM 
--  
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

declare objexist number;
begin 
    select count(*) into objexist from user_types where type_name='ATTRIBUTEINFO';
    if objexist = 0 then 
        execute immediate 'create or replace TYPE  attributeinfo AS OBJECT (attName VARCHAR2 ( 100 ), attType VARCHAR2 ( 100 ), creatable INTEGER , updatable INTEGER , required INTEGER , readable INTEGER)' ; 
    end if;
end;
/

declare objexist number;
begin 
    select count(*) into objexist from user_types where type_name='ATTRIBUTELIST';
    if objexist = 0 then 
        execute immediate 'create or replace type attributelist  is varray(100) of attributeinfo' ; 
    end if;
end;
/

declare objexist number;
begin 
    select count(*) into objexist from user_types where type_name='SCHEMA_OBJECT';
    if objexist = 0 then 
        execute immediate 'create or replace TYPE schema_object AS OBJECT ( schemaname VARCHAR2 ( 100 ), attr  attributelist)' ; 
    end if;
end;
/

declare objexist number;
begin 
    select count(*) into objexist from user_types where type_name='SCHEMALIST';
    if objexist = 0 then 
        execute immediate 'create or replace type schemalist is varray(50) of schema_object' ; 
    end if;
end;
/

