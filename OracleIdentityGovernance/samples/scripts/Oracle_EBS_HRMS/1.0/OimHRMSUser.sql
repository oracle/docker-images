-- Copyright (c) 2023 Oracle and/or its affiliates.
-- 
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
-- 
--  Author: OIG Development
-- 
--  Description: Script file for Creating: Database User & for Granting basic privileges, like: Connect, Create synonym & alter procedure
--  
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

Accept USERNAME prompt"Enter New database Username to be created::"
Accept USERPWD prompt"Enter the New user password::" hide
CREATE USER &USERNAME identified by &USERPWD;
alter user &USERNAME enable editions;
prompt grant connect, resource to &USERNAME;
grant connect, resource to &USERNAME;

prompt grant create synonym to &USERNAME;
grant create synonym to &USERNAME;

prompt grant alter any procedure to &USERNAME;
grant alter any procedure to &USERNAME;
