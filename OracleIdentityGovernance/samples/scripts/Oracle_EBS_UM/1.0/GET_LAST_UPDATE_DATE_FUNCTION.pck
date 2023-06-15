-- Copyright (c) 2023 Oracle and/or its affiliates.
-- 
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
-- 
--  Author: OIG Development
-- 
--  Description: Script file for EXECUTE Grant on procedures/packages and Tables required for OIM database USER
--  
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

-- function that gets latest date from roles and responsibilities
create or replace function get_last_update_date(p_user_id IN NUMBER) return date
result_cache is
   l_lastupdate_date date;
begin
 select max(l_max_date) into l_lastupdate_date from ( 
     (select rol.last_update_date l_max_date
      from  fnd_user f, wf_user_role_assignments rol
      where f.user_id = p_user_id
            and rol.user_name = f.user_name
            and rol.role_name like 'UMX%') 
      union all
      select /*+ index(resp.wur WF_LOCAL_USER_ROLES_U1) */ resp.last_update_date l_max_date 
      from  FND_USER_RESP_GROUPS_DIRECT resp 
      where resp.user_id = p_user_id 
      union all
      select last_update_date l_max_date from fnd_user where user_id=p_user_id);

	  return l_lastupdate_date;

end;

/
