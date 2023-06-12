-- Copyright (c) 2023 Oracle and/or its affiliates.
-- 
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
-- 
--  Author: OIG Development
-- 
--  Description: Script file for EXECUTE Grant on procedures/packages and Tables required for HRMS
--  
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

accept hostname prompt"Enter the hostname for network acl [Input will be ignored If DB version is earlier than 11g] ::";
/

DECLARE majorversion number;
BEGIN
    select REGEXP_SUBSTR(version, '[^.]+', 1, 1) into majorversion FROM V$INSTANCE;
    if majorversion > 10  then
        DBMS_NETWORK_ACL_ADMIN.add_privilege('OracleEBS.xml', UPPER('&USERNAME'), TRUE, 'connect'); 
        DBMS_NETWORK_ACL_ADMIN.assign_acl ( acl        => 'OracleEBS.xml',  host       => '&hostname');
    else
        dbms_output.put_line('Ignoring assigning network acl');
    end if;
END;
/

COMMIT;
/
