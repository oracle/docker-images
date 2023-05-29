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
