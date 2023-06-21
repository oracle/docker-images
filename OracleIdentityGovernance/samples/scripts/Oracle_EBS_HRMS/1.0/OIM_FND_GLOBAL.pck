-- Copyright (c) 2023 Oracle and/or its affiliates.
-- 
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
-- 
--  Author: OIG Development
-- 
--  Description: Script file for CREATING synonym of procedures/packages and Tables required for HRMS
--  
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

create or replace package OIM_FND_GLOBAL is

-- Public function and procedure declarations

----------------------------------------------------------------------
--
-- APPS_INITIALIZE - Setup PL/SQL security context
--
-- This procedure may be called to initialize the global security
-- context for a database session.  This should only be done when
-- the session is established outside of a normal forms or
-- concurrent program connection.
--
-- IN
--   FND User ID
--   FND Responsibility ID (two part key, resp_id / resp_appl_id)
--   FND Security Group ID
--
procedure APPS_INITIALIZE(
    user_id in number,
    resp_id in number,
    resp_appl_id in number,
    security_group_id in number default 0,
    server_id in number default -1);
                                 
end OIM_FND_GLOBAL;
/
create or replace package body OIM_FND_GLOBAL is

----------------------------------------------------------------------
-- This procedure may be called to initialize the global security
-- context for a database session.  This should only be done when
-- the session is established outside of a normal forms or
-- concurrent program connection.
--
-- IN
--   FND User ID
--   FND Responsibility ID (two part key, resp_id / resp_appl_id)
--   FND Security Group ID
--
procedure APPS_INITIALIZE(
    user_id in number,
    resp_id in number,
    resp_appl_id in number,
    security_group_id in number default 0,
    server_id in number default -1) is
begin
  FND_GLOBAL.APPS_INITIALIZE(
    user_id ,
    resp_id ,
    resp_appl_id ,
    security_group_id ,
    server_id);
end APPS_INITIALIZE;

end OIM_FND_GLOBAL;
/
