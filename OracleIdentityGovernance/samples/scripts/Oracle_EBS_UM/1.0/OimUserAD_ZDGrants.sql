-- Copyright (c) 2023 Oracle and/or its affiliates.
-- 
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
-- 
--  Author: OIG Development
-- 
--  Description: Script file for EXECUTE Grant on procedures/packages and Tables required for OIM database USER
--  
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

---- EXECUTE Grant on procedures/packages required for OIM database USER ----

prompt exec AD_ZD.grant_privs('EXECUTE','WF_LOCAL_SYNCH','&USERNAME');
exec AD_ZD.grant_privs('EXECUTE','WF_LOCAL_SYNCH','&USERNAME'); 

prompt exec AD_ZD.grant_privs('EXECUTE','FND_USER_PKG','&USERNAME');
exec AD_ZD.grant_privs('EXECUTE','FND_USER_PKG','&USERNAME'); 

prompt exec AD_ZD.grant_privs('EXECUTE','FND_API','&USERNAME');
exec AD_ZD.grant_privs('EXECUTE','FND_API','&USERNAME'); 

prompt exec AD_ZD.grant_privs('EXECUTE','FND_GLOBAL','&USERNAME');
exec AD_ZD.grant_privs('EXECUTE','FND_GLOBAL','&USERNAME'); 

prompt exec AD_ZD.grant_privs('EXECUTE','UMX_ACCESS_ROLES_PVT','&USERNAME');
exec AD_ZD.grant_privs('EXECUTE','UMX_ACCESS_ROLES_PVT','&USERNAME'); 

prompt exec AD_ZD.grant_privs('EXECUTE','FND_USER_RESP_GROUPS_API','&USERNAME');
exec AD_ZD.grant_privs('EXECUTE','FND_USER_RESP_GROUPS_API','&USERNAME'); 

prompt exec AD_ZD.grant_privs('EXECUTE','ICX_USER_SEC_ATTR_PUB','&USERNAME');
exec AD_ZD.grant_privs('EXECUTE','ICX_USER_SEC_ATTR_PUB','&USERNAME'); 

---- SELECT Grant on tables required for OIM database USER ----

prompt exec AD_ZD.grant_privs('SELECT','FND_APPLICATION','&USERNAME');
exec AD_ZD.grant_privs('SELECT','FND_APPLICATION','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','FND_RESPONSIBILITY','&USERNAME');
exec AD_ZD.grant_privs('SELECT','FND_RESPONSIBILITY','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','FND_RESPONSIBILITY_TL','&USERNAME');
exec AD_ZD.grant_privs('SELECT','FND_RESPONSIBILITY_TL','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','FND_USER_RESP_GROUPS_DIRECT','&USERNAME');
exec AD_ZD.grant_privs('SELECT','FND_USER_RESP_GROUPS_DIRECT','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','FND_APPLICATION_VL','&USERNAME');
exec AD_ZD.grant_privs('SELECT','FND_APPLICATION_VL','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','FND_RESPONSIBILITY_VL','&USERNAME');
exec AD_ZD.grant_privs('SELECT','FND_RESPONSIBILITY_VL','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','FND_SECURITY_GROUPS_VL','&USERNAME');
exec AD_ZD.grant_privs('SELECT','FND_SECURITY_GROUPS_VL','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','FND_USER_RESP_GROUPS_DIRECT','&USERNAME');
exec AD_ZD.grant_privs('SELECT','FND_USER_RESP_GROUPS_DIRECT','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','PER_ALL_PEOPLE_F','&USERNAME');
exec AD_ZD.grant_privs('SELECT','PER_ALL_PEOPLE_F','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','FND_APPLICATION_TL','&USERNAME');
exec AD_ZD.grant_privs('SELECT','FND_APPLICATION_TL','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','WF_LOCAL_USER_ROLES','&USERNAME');
exec AD_ZD.grant_privs('SELECT','WF_LOCAL_USER_ROLES','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','WF_USER_ROLES','&USERNAME');
exec AD_ZD.grant_privs('SELECT','WF_USER_ROLES','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','WF_LOCAL_ROLES','&USERNAME');
exec AD_ZD.grant_privs('SELECT','WF_LOCAL_ROLES','&USERNAME');

---- SELECT, UPDATE Grant on tables required for OIM database USER ----

prompt exec AD_ZD.grant_privs('SELECT','FND_USER','&USERNAME');
exec AD_ZD.grant_privs('SELECT','FND_USER','&USERNAME');
prompt exec AD_ZD.grant_privs('UPDATE','FND_USER','&USERNAME');
exec AD_ZD.grant_privs('UPDATE','FND_USER','&USERNAME');

-- Grant execute privileges to the wrapper packages created in APPS schema

prompt exec AD_ZD.grant_privs('EXECUTE','OIM_FND_GLOBAL','&USERNAME');
exec AD_ZD.grant_privs('EXECUTE','OIM_FND_GLOBAL','&USERNAME');

prompt exec AD_ZD.grant_privs('EXECUTE','OIM_FND_USER_TCA_PKG','&USERNAME');
exec AD_ZD.grant_privs('EXECUTE','OIM_FND_USER_TCA_PKG','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','FND_SECURITY_GROUPS','&USERNAME');
exec AD_ZD.grant_privs('SELECT','FND_SECURITY_GROUPS','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','FND_SECURITY_GROUPS_TL','&USERNAME');
exec AD_ZD.grant_privs('SELECT','FND_SECURITY_GROUPS_TL','&USERNAME');

prompt exec AD_ZD.grant_privs('EXECUTE','FND_OID_USERS','&USERNAME');
exec AD_ZD.grant_privs('EXECUTE','FND_OID_USERS','&USERNAME');

prompt exec AD_ZD.grant_privs('EXECUTE','FND_OID_UTIL','&USERNAME');
exec AD_ZD.grant_privs('EXECUTE','FND_OID_UTIL','&USERNAME');

---- SELECT, UPDATE Grant on tables required for OIM database USER ----

prompt exec AD_ZD.grant_privs('SELECT','HZ_PARTIES','&USERNAME');
exec AD_ZD.grant_privs('SELECT','HZ_PARTIES','&USERNAME');
prompt exec AD_ZD.grant_privs('UPDATE','HZ_PARTIES','&USERNAME');
exec AD_ZD.grant_privs('UPDATE','HZ_PARTIES','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','HZ_PERSON_PROFILES','&USERNAME');
exec AD_ZD.grant_privs('SELECT','HZ_PERSON_PROFILES','&USERNAME');
prompt exec AD_ZD.grant_privs('UPDATE','HZ_PERSON_PROFILES','&USERNAME');
exec AD_ZD.grant_privs('UPDATE','HZ_PERSON_PROFILES','&USERNAME');

-- Grant execute privileges to the wrapper packages created in APPS schema

prompt exec AD_ZD.grant_privs('SELECT','AP_SUPPLIERS','&USERNAME');
exec AD_ZD.grant_privs('SELECT','AP_SUPPLIERS','&USERNAME');
prompt exec AD_ZD.grant_privs('UPDATE','AP_SUPPLIERS','&USERNAME');
exec AD_ZD.grant_privs('UPDATE','AP_SUPPLIERS','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','AP_SUPPLIER_CONTACTS','&USERNAME');
exec AD_ZD.grant_privs('SELECT','AP_SUPPLIER_CONTACTS','&USERNAME');
prompt exec AD_ZD.grant_privs('UPDATE','AP_SUPPLIER_CONTACTS','&USERNAME');
exec AD_ZD.grant_privs('UPDATE','AP_SUPPLIER_CONTACTS','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','HZ_RELATIONSHIPS','&USERNAME');
exec AD_ZD.grant_privs('SELECT','HZ_RELATIONSHIPS','&USERNAME');
prompt exec AD_ZD.grant_privs('UPDATE','HZ_RELATIONSHIPS','&USERNAME');
exec AD_ZD.grant_privs('UPDATE','HZ_RELATIONSHIPS','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','UMX_ROLE_ASSIGNMENTS_V','&USERNAME');
exec AD_ZD.grant_privs('SELECT','UMX_ROLE_ASSIGNMENTS_V','&USERNAME');
prompt exec AD_ZD.grant_privs('UPDATE','UMX_ROLE_ASSIGNMENTS_V','&USERNAME');
exec AD_ZD.grant_privs('UPDATE','UMX_ROLE_ASSIGNMENTS_V','&USERNAME');

prompt exec AD_ZD.grant_privs('SELECT','WF_USER_ROLE_ASSIGNMENTS','&USERNAME');
exec AD_ZD.grant_privs('SELECT','WF_USER_ROLE_ASSIGNMENTS','&USERNAME');
prompt exec AD_ZD.grant_privs('UPDATE','WF_USER_ROLE_ASSIGNMENTS','&USERNAME');
exec AD_ZD.grant_privs('UPDATE','WF_USER_ROLE_ASSIGNMENTS','&USERNAME');
