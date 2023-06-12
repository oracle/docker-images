-- Copyright (c) 2023 Oracle and/or its affiliates.
-- 
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
-- 
--  Author: OIG Development
-- 
--  Description: Script file for CREATING synonym of procedures/packages and Tables required for OIM database USER
--  
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

prompt Connecting &USERNAME;
accept Databasename prompt"Enter the name of the database ::";
connect &USERNAME/&USERPWD@&Databasename;

prompt create or replace synonym FND_RESPONSIBILITY for APPS.FND_RESPONSIBILITY;
create or replace synonym FND_RESPONSIBILITY for APPS.FND_RESPONSIBILITY;

prompt create or replace synonym FND_APPLICATION for apps.FND_APPLICATION;
create or replace synonym FND_APPLICATION for apps.FND_APPLICATION;

prompt create or replace synonym FND_RESPONSIBILITY_VL for APPS.FND_RESPONSIBILITY_VL;
create or replace synonym FND_RESPONSIBILITY_VL for APPS.FND_RESPONSIBILITY_VL;

prompt create or replace synonym FND_SECURITY_GROUPS_VL for APPS.FND_SECURITY_GROUPS_VL;
create or replace synonym FND_SECURITY_GROUPS_VL for APPS.FND_SECURITY_GROUPS_VL;

prompt create or replace synonym FND_APPLICATION_VL for APPS.FND_APPLICATION_VL;
create or replace synonym FND_APPLICATION_VL for APPS.FND_APPLICATION_VL;

prompt create or replace synonym FND_USER_RESP_GROUPS_DIRECT for apps.FND_USER_RESP_GROUPS_DIRECT;
create or replace synonym FND_USER_RESP_GROUPS_DIRECT for apps.FND_USER_RESP_GROUPS_DIRECT;

prompt create or replace synonym FND_USER for APPS.FND_USER;
create or replace synonym FND_USER for APPS.FND_USER;

prompt create or replace synonym FND_RESPONSIBILITY_TL for APPS.FND_RESPONSIBILITY_TL;
create or replace synonym FND_RESPONSIBILITY_TL for APPS.FND_RESPONSIBILITY_TL;

prompt create or replace synonym FND_USER_RESP_GROUPS_DIRECT for apps.FND_USER_RESP_GROUPS_DIRECT;
create or replace synonym FND_USER_RESP_GROUPS_DIRECT for apps.FND_USER_RESP_GROUPS_DIRECT;

prompt create or replace synonym PER_ALL_PEOPLE_F for APPS.PER_ALL_PEOPLE_F ;
create or replace synonym PER_ALL_PEOPLE_F  for APPS.PER_ALL_PEOPLE_F ;

prompt create or replace synonym FND_APPLICATION_TL for APPS.FND_APPLICATION_TL;
create or replace synonym FND_APPLICATION_TL for APPS.FND_APPLICATION_TL;

prompt create or replace synonym WF_LOCAL_USER_ROLES for APPS.WF_LOCAL_USER_ROLES;
create or replace synonym WF_LOCAL_USER_ROLES for APPS.WF_LOCAL_USER_ROLES;

prompt create or replace synonym WF_USER_ROLES for APPS.WF_USER_ROLES;
create or replace synonym WF_USER_ROLES for APPS.WF_USER_ROLES;

prompt create or replace synonym WF_LOCAL_ROLES for APPS.WF_LOCAL_ROLES;
create or replace synonym WF_LOCAL_ROLES for APPS.WF_LOCAL_ROLES;

prompt create or replace synonym FND_API for APPS.FND_API;
create or replace synonym FND_API for APPS.FND_API;

prompt create or replace synonym FND_SECURITY_GROUPS for APPS.FND_SECURITY_GROUPS;
create or replace synonym FND_SECURITY_GROUPS for APPS.FND_SECURITY_GROUPS;

prompt create or replace synonym FND_SECURITY_GROUPS_TL for APPS.FND_SECURITY_GROUPS_TL;
create or replace synonym FND_SECURITY_GROUPS_TL for APPS.FND_SECURITY_GROUPS_TL;

prompt create or replace synonym HZ_PARTIES for APPS.HZ_PARTIES;
create or replace synonym HZ_PARTIES for APPS.HZ_PARTIES;

prompt create or replace synonym HZ_PERSON_PROFILES for APPS.HZ_PERSON_PROFILES;
create or replace synonym HZ_PERSON_PROFILES for APPS.HZ_PERSON_PROFILES;

prompt create or replace synonym FND_OID_USERS for APPS.FND_OID_USERS;
create or replace synonym FND_OID_USERS for APPS.FND_OID_USERS;

prompt create or replace synonym FND_OID_UTIL for APPS.FND_OID_UTIL;
create or replace synonym FND_OID_UTIL for APPS.FND_OID_UTIL;

prompt create or replace synonym UMX_ROLE_ASSIGNMENTS_V for APPS.UMX_ROLE_ASSIGNMENTS_V;
create or replace synonym UMX_ROLE_ASSIGNMENTS_V for APPS.UMX_ROLE_ASSIGNMENTS_V;

prompt create or replace synonym WF_USER_ROLE_ASSIGNMENTS for APPS.WF_USER_ROLE_ASSIGNMENTS;
create or replace synonym WF_USER_ROLE_ASSIGNMENTS for APPS.WF_USER_ROLE_ASSIGNMENTS;

prompt create or replace synonym AP_SUPPLIERS for APPS.AP_SUPPLIERS;
create or replace synonym AP_SUPPLIERS for APPS.AP_SUPPLIERS;

prompt create or replace synonym AP_SUPPLIER_CONTACTS for APPS.AP_SUPPLIER_CONTACTS;
create or replace synonym AP_SUPPLIER_CONTACTS for APPS.AP_SUPPLIER_CONTACTS;

prompt create or replace synonym HZ_RELATIONSHIPS for APPS.HZ_RELATIONSHIPS;
create or replace synonym HZ_RELATIONSHIPS for APPS.HZ_RELATIONSHIPS;

prompt create or replace synonym ICX_USER_SEC_ATTR_PUB for APPS.ICX_USER_SEC_ATTR_PUB;
create or replace synonym ICX_USER_SEC_ATTR_PUB for APPS.ICX_USER_SEC_ATTR_PUB;
