-- Copyright (c) 2023 Oracle and/or its affiliates.
-- 
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
-- 
--  Author: OIG Development
-- 
--  Description: Script file for CREATING synonym of procedures/packages using previously created OimUserAppstablesSynonyms
--  
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

prompt Connecting &USERNAME;
accept Databasename prompt"Enter the name of the database ::";
connect &USERNAME/&USERPWD@&Databasename;


prompt create or replace synonym OIM_FND_USER_TCA_PKG for APPS.OIM_FND_USER_TCA_PKG;
create or replace synonym OIM_FND_USER_TCA_PKG for APPS.OIM_FND_USER_TCA_PKG;

prompt create or replace synonym OIM_FND_GLOBAL for APPS.OIM_FND_GLOBAL;
create or replace synonym OIM_FND_GLOBAL for APPS.OIM_FND_GLOBAL;

prompt create or replace synonym WF_LOCAL_SYNCH for APPS.WF_LOCAL_SYNCH;
create or replace synonym WF_LOCAL_SYNCH for APPS.WF_LOCAL_SYNCH;
