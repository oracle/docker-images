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

prompt grant execute on APPS.WF_LOCAL_SYNCH to &USERNAME;
grant execute on APPS.WF_LOCAL_SYNCH to &USERNAME;

prompt grant execute on APPS.FND_USER_PKG to &USERNAME;
grant execute on APPS.FND_USER_PKG to &USERNAME;

prompt grant execute on APPS.FND_API to &USERNAME;
grant execute on APPS.FND_API to &USERNAME;

prompt grant execute on APPS.FND_GLOBAL to &USERNAME;
grant execute on APPS.FND_GLOBAL to &USERNAME;

prompt grant execute on APPS.UMX_ACCESS_ROLES_PVT to &USERNAME;
grant execute on APPS.UMX_ACCESS_ROLES_PVT to &USERNAME;

prompt grant execute on APPS.FND_USER_RESP_GROUPS_API to &USERNAME;
grant execute on APPS.FND_USER_RESP_GROUPS_API to &USERNAME;

prompt grant execute on APPS.ICX_USER_SEC_ATTR_PUB to &USERNAME;
grant execute on APPS.ICX_USER_SEC_ATTR_PUB to &USERNAME;

---- SELECT Grant on tables required for OIM database USER ----

prompt grant select on APPS.FND_APPLICATION to &USERNAME;
grant select on APPS.FND_APPLICATION to &USERNAME;

prompt grant select on APPS.FND_RESPONSIBILITY to &USERNAME;
grant select on APPS.FND_RESPONSIBILITY to &USERNAME;

prompt grant select on APPS.FND_RESPONSIBILITY_TL to &USERNAME;
grant select on APPS.FND_RESPONSIBILITY_TL to &USERNAME;

prompt grant select on APPS.FND_USER_RESP_GROUPS_DIRECT to &USERNAME;
grant select on APPS.FND_USER_RESP_GROUPS_DIRECT to &USERNAME;

prompt grant select on APPS.fnd_application_vl  to &USERNAME;
grant select on APPS.fnd_application_vl  to &USERNAME;


prompt grant select on APPS.FND_RESPONSIBILITY_VL to &USERNAME;
grant select on APPS.fnd_responsibility_vl to &USERNAME;


prompt grant select on APPS.fnd_security_groups_vl to &USERNAME;
grant select on APPS.fnd_security_groups_vl to &USERNAME;

prompt grant select on APPS.FND_USER_RESP_GROUPS_DIRECT  to &USERNAME;
grant select on APPS.FND_USER_RESP_GROUPS_DIRECT  to &USERNAME;

prompt grant select on APPS.PER_ALL_PEOPLE_F to &USERNAME;
grant select on APPS.PER_ALL_PEOPLE_F to &USERNAME;

prompt grant select on APPS.FND_APPLICATION_TL to &USERNAME;
grant select on APPS.FND_APPLICATION_TL to &USERNAME;

prompt grant select on APPS.WF_LOCAL_USER_ROLES to &USERNAME;
grant select on APPS.WF_LOCAL_USER_ROLES to &USERNAME;

prompt grant select on APPS.WF_USER_ROLES to &USERNAME;
grant select on APPS.WF_USER_ROLES to &USERNAME;

prompt grant select on APPS.WF_LOCAL_ROLES to &USERNAME;
grant select on APPS.WF_LOCAL_ROLES to &USERNAME;

---- SELECT, UPDATE Grant on tables required for OIM database USER ----

prompt grant select, update on APPS.FND_USER to &USERNAME; 
grant select, update on APPS.FND_USER to &USERNAME;


-- Grant execute privileges to the wrapper packages created in APPS schema

prompt grant execute on APPS.OIM_FND_GLOBAL to &USERNAME; 
grant execute on APPS.OIM_FND_GLOBAL to &USERNAME;

prompt grant execute on APPS.OIM_FND_USER_TCA_PKG to &USERNAME; 
grant execute on APPS.OIM_FND_USER_TCA_PKG to &USERNAME;

prompt grant select on apps.fnd_security_groups to &USERNAME;
grant select on apps.fnd_security_groups to &USERNAME;

prompt grant select on apps.fnd_security_groups_tl to &USERNAME;
grant select on apps.fnd_security_groups_tl to &USERNAME;

prompt grant execute on APPS.FND_OID_USERS to &USERNAME;
grant execute on APPS.FND_OID_USERS to &USERNAME;

prompt grant execute on APPS.FND_OID_UTIL to &USERNAME;
grant execute on APPS.FND_OID_UTIL to &USERNAME;

---- SELECT, UPDATE Grant on tables required for OIM database USER ----

prompt grant select, update on APPS.HZ_PARTIES to &USERNAME; 
grant select, update on APPS.HZ_PARTIES to &USERNAME;

prompt grant select, update on APPS.HZ_PERSON_PROFILES to &USERNAME; 
grant select, update on APPS.HZ_PERSON_PROFILES to &USERNAME;

-- Grant execute privileges to the wrapper packages created in APPS schema

prompt grant select, update on APPS.ap_suppliers to &USERNAME; 
grant select, update on APPS.ap_suppliers to &USERNAME;


prompt grant select, update on APPS.ap_supplier_contacts to &USERNAME; 
grant select, update on APPS.ap_supplier_contacts to &USERNAME;


prompt grant select, update on APPS.hz_relationships to &USERNAME; 
grant select, update on APPS.hz_relationships to &USERNAME;

prompt grant select, update on APPS.umx_role_assignments_v to &USERNAME; 
grant select, update on APPS.umx_role_assignments_v to &USERNAME;

prompt grant select, update on APPS.wf_user_role_assignments to &USERNAME; 
grant select, update on APPS.wf_user_role_assignments to &USERNAME;

