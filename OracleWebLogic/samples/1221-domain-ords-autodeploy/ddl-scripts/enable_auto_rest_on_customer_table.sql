DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    ORDS.ENABLE_OBJECT(p_enabled => TRUE,
                       p_schema => 'PDBADMIN',
                       p_object => 'CUSTOMER',
                       p_object_type => 'TABLE',
                       p_object_alias => 'customer',
                       p_auto_rest_auth => FALSE);
    commit;
END;
/
