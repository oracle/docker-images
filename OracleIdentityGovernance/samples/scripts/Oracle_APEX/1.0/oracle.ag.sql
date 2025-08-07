

DECLARE
l_roles     OWA.VC_ARR;
  l_modules   OWA.VC_ARR;
  l_patterns  OWA.VC_ARR;

BEGIN
  ORDS.ENABLE_SCHEMA(
      p_enabled             => TRUE,
      p_url_mapping_type    => 'BASE_PATH',
      p_auto_rest_auth      => FALSE);

  ORDS.DEFINE_MODULE(
      p_module_name    => 'oracle.ag',
      p_base_path      => '/oracleag/',
      p_items_per_page => 100,
      p_status         => 'PUBLISHED',
      p_comments       => 'Parent module');

  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'workspaces',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'workspaces',
      p_method         => 'GET',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_limit         NUMBER := NVL(:limit, 100);
    l_offset        NUMBER := NVL(:offset, 0);
    l_count         NUMBER;
    l_workspace_id  APEX_WORKSPACE_SCHEMAS.WORKSPACE_ID%TYPE;

    l_max_limit  CONSTANT NUMBER := 1000;

    -- Helper to write error JSON
    PROCEDURE write_error(p_status OUT NUMBER, p_http_status NUMBER, p_message VARCHAR2) IS
    BEGIN
        APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'');
            APEX_JSON.write(''message'', p_message);
        APEX_JSON.close_object;
        p_status := p_http_status;
    END;

BEGIN
    -- Sanitize limit and offset
    IF l_limit < 0 THEN
        l_limit := 100;
    ELSIF l_limit > l_max_limit THEN
        l_limit := l_max_limit;
    END IF;

    IF l_offset < 0 THEN
        l_offset := 0;
    END IF;

    IF :workspaceName IS NOT NULL THEN
        BEGIN
            SELECT workspace_id
              INTO l_workspace_id
              FROM apex_workspace_schemas
             WHERE workspace_' || 'name = UPPER(:workspaceName);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                write_error(:status, 400, ''Workspace name not available: '' || :workspaceName);
                RETURN;
        END;
    END IF;

    -- Get total count
    SELECT COUNT(*)
      INTO l_count
      FROM apex_workspace_schemas
     WHERE (:workspaceName IS NULL OR workspace_id = l_workspace_id)
        AND workspace_id not in (10, 11, 12);


    -- Begin JSON
    APEX_JSON.open_object;
        APEX_JSON.open_array(''items'');

        -- Fetch paginated data
        FOR rec IN (
            SELECT 
                workspace_id AS id,
                workspace_name AS name,
                workspace_display_name AS display_name,
                schema
            FROM apex_workspace_schemas
            WHERE (:workspaceName IS NULL OR workspace_id = l_workspace_id)
            AND workspace_id not in (10, 11, 12)
            ORDER BY workspace_name
            OFFSET l_offset ROWS FETCH NEXT ' || 'l_limit ROWS ONLY
        ) LOOP
            APEX_JSON.open_object;
            APEX_JSON.write(''id'', TO_CHAR(rec.id));
            APEX_JSON.write(''name'', rec.name);
            APEX_JSON.write(''display_name'', rec.display_name);
            APEX_JSON.write(''schema'', rec.schema);
            APEX_JSON.close_object;
        END LOOP;

        APEX_JSON.close_array;

    -- Pagination info
    APEX_JSON.write(''count'', l_count);
    APEX_JSON.write(''limit'', l_limit);
    APEX_JSON.write(''offset'', l_offset);
    APEX_JSON.write(''hasMore'', (l_offset + l_limit) < l_count);

    APEX_JSON.close_object;

    :status := 200;

EXCEPTION
    WHEN OTHERS THEN
        write_error(:status, 500, ''Unexpected error: '' || SQLERRM);
END;');

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'workspaces',
      p_method             => 'GET',
      p_name               => 'workspaceName',
      p_bind_variable_name => 'workspaceName',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'workspaces',
      p_method             => 'GET',
      p_name               => 'X-ORDS-STATUS-CODE',
      p_bind_variable_name => 'status',
      p_source_type        => 'HEADER',
      p_param_type         => 'INT',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'workspaces',
      p_method             => 'GET',
      p_name               => 'items',
      p_bind_variable_name => 'items',
      p_source_type        => 'RESPONSE',
      p_param_type         => 'RESULTSET',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'workspaces',
      p_method             => 'GET',
      p_name               => 'limit',
      p_bind_variable_name => 'limit',
      p_source_type        => 'URI',
      p_param_type         => 'INT',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'workspaces',
      p_method             => 'GET',
      p_name               => 'offset',
      p_bind_variable_name => 'offset',
      p_source_type        => 'URI',
      p_param_type         => 'INT',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'groups',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'groups',
      p_method         => 'GET',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_limit         NUMBER := NVL(:limit, 100);
    l_offset        NUMBER := NVL(:offset, 0);
    l_count         NUMBER;
    l_workspace_id  APEX_WORKSPACE_SCHEMAS.WORKSPACE_ID%TYPE;

    l_max_limit  CONSTANT NUMBER := 1000;

    -- Helper to write error JSON
    PROCEDURE write_error(p_status OUT NUMBER, p_http_status NUMBER, p_message VARCHAR2) IS
    BEGIN
        APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'');
            APEX_JSON.write(''message'', p_message);
        APEX_JSON.close_object;
        p_status := p_http_status;
    END;

BEGIN
    -- Validate and cap limit/offset
    IF l_limit < 0 THEN
        l_limit := 100;
    ELSIF l_limit > l_max_limit THEN
        l_limit := l_max_limit;
    END IF;

    IF l_offset < 0 THEN
        l_offset := 0;
    END IF;


    IF :workspaceName IS NOT NULL THEN
        BEGIN
            SELECT workspace_id
              INTO l_workspace_id
              FROM apex_workspace_schemas
             WHERE works' || 'pace_name = UPPER(:workspaceName);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                write_error(:status, 400, ''Workspace name not available: '' || :workspaceName);
                RETURN;
        END;
    END IF;

    -- Get total count of groups
    SELECT COUNT(*)
      INTO l_count
      FROM apex_workspace_groups
     WHERE (:workspaceName IS NULL OR workspace_id = l_workspace_id)
        AND APPLICATION_ID IS NULL;

    -- Begin JSON object
    APEX_JSON.open_object;

    -- Start array of items
        APEX_JSON.open_array(''items'');

            -- Fetch paginated group records
            FOR rec IN (
                SELECT 
                    workspace_id,
                    workspace_name,
                    group_name,
                    group_desc
                FROM apex_workspace_groups
                WHERE (:workspaceName IS NULL OR workspace_id in(l_workspace_id, 10))
                    AND APPLICATION_ID IS NULL
                ORDER BY worksp' || 'ace_id
                OFFSET l_offset ROWS 
                FETCH NEXT l_limit ROWS ONLY
            ) LOOP
                APEX_JSON.open_object;
                    APEX_JSON.write(''id'', rec.workspace_id || ''::'' || rec.group_name);
                    APEX_JSON.write(''name'',  rec.workspace_name || ''::'' || rec.group_name);
                    APEX_JSON.write(''display_name'',  rec.group_name);
                    APEX_JSON.write(''workspace_id'', TO_CHAR(rec.workspace_id));
                    APEX_JSON.write(''workspace_name'', rec.workspace_name);
                    -- Dynamic group_desc logic
                    IF rec.workspace_id = 10 THEN
                        APEX_JSON.write(''group_desc'', rec.group_desc || '', applicable to all workspaces'');
                    ELSIF rec.group_desc IS NOT NULL THEN
                        APEX_JSON.write(''group_desc'', rec.group_desc || '', applicable to '' || rec.workspace_name || '' workspace'');
                    ELSE
                        APEX_' || 'JSON.write(''group_desc'', ''Applicable to '' || rec.workspace_name || '' workspace'');
                    END IF;
                APEX_JSON.close_object;
            END LOOP;

        APEX_JSON.close_array;

    -- Write pagination metadata
    APEX_JSON.write(''count'',    l_count);
    APEX_JSON.write(''limit'',    l_limit);
    APEX_JSON.write(''offset'',   l_offset);
    APEX_JSON.write(''hasMore'',  (l_offset + l_limit) < l_count);

    APEX_JSON.close_object;

    -- Success HTTP status
    :status := 200;

EXCEPTION
    WHEN OTHERS THEN
        write_error(:status, 500, ''Unexpected error: '' || SQLERRM);
END;');

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'groups',
      p_method             => 'GET',
      p_name               => 'workspaceName',
      p_bind_variable_name => 'workspaceName',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'groups',
      p_method             => 'GET',
      p_name               => 'X-ORDS-STATUS-CODE',
      p_bind_variable_name => 'status',
      p_source_type        => 'HEADER',
      p_param_type         => 'INT',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'groups',
      p_method             => 'GET',
      p_name               => 'limit',
      p_bind_variable_name => 'limit',
      p_source_type        => 'URI',
      p_param_type         => 'INT',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'groups',
      p_method             => 'GET',
      p_name               => 'offset',
      p_bind_variable_name => 'offset',
      p_source_type        => 'URI',
      p_param_type         => 'INT',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'privileges',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'privileges',
      p_method         => 'GET',
      p_source_type    => 'json/collection',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'WITH developer_privilege (name, id, description) AS (
    SELECT ''Workspace Administrator'', ''ADMIN'', ''ADMIN''                                  FROM DUAL UNION ALL
    SELECT ''App Builder Access for developer'', ''DEVELOPER_APP_BUILDER'', ''CREATE:EDIT:MONITOR:HELP''    FROM DUAL UNION ALL
    SELECT ''SQL Workshop Access for developer'', ''DEVELOPER_SQL_WORKSHOP'', ''SQL:DATA_LOADER:MONITOR''    FROM DUAL
)
SELECT 
    dp.name,
    dp.id,
    dp.description
FROM 
    developer_privilege dp');

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'privileges',
      p_method             => 'GET',
      p_name               => 'X-ORDS-STATUS-CODE',
      p_bind_variable_name => 'status',
      p_source_type        => 'HEADER',
      p_param_type         => 'INT',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'privileges',
      p_method             => 'GET',
      p_name               => 'items',
      p_bind_variable_name => 'items',
      p_source_type        => 'RESPONSE',
      p_param_type         => 'RESULTSET',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'user',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'user',
      p_method         => 'GET',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_input         VARCHAR2(200) := :id;
    l_ws_id_1       NUMBER;
    l_user_name     VARCHAR2(100);
    l_pos           PLS_INTEGER;

    l_limit         NUMBER := NVL(:limit, 100);
    l_offset        NUMBER := NVL(:offset, 0);
    l_count         NUMBER;
    l_ws_name       VARCHAR2(100) := :workspaceName;
    l_ws_id_2       APEX_WORKSPACE_SCHEMAS.WORKSPACE_ID%TYPE;

    -- Helper to write error JSON
    PROCEDURE write_error(p_status OUT NUMBER, p_http_status NUMBER, p_message VARCHAR2) IS
    BEGIN
        APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'');
            APEX_JSON.write(''message'', p_message);
        APEX_JSON.close_object;
        p_status := p_http_status;
    END;

    -- Procedure to write user JSON object
    PROCEDURE write_user_json(rec apex_workspace_apex_users%ROWTYPE) IS
    BEGIN
        APEX_JSON.open_object;
            APEX_JSON.write(''id'',                       rec.WORKSPACE_ID || ''::'' || rec.USER_NAME);
            APE' || 'X_JSON.write(''user_name'',                rec.WORKSPACE_NAME || ''::'' || rec.USER_NAME);
            APEX_JSON.write(''workspace_user_name'',      rec.USER_NAME);
            APEX_JSON.write(''workspace_id'',             TO_CHAR(rec.WORKSPACE_ID));
            APEX_JSON.write(''first_name'',               rec.FIRST_NAME);
            APEX_JSON.write(''last_name'',                rec.LAST_NAME);
            APEX_JSON.write(''email_address'',            rec.EMAIL);
            APEX_JSON.write(''account_locked'',           UPPER(rec.ACCOUNT_LOCKED) IN (''Y'', ''YES''));
            APEX_JSON.write(''description'',              rec.DESCRIPTION);
            APEX_JSON.write(''default_schema'',           rec.FIRST_SCHEMA_PROVISIONED);
            APEX_JSON.write(''available_schemas'',        rec.available_schemas);
            APEX_JSON.write(''date_created'',             TO_CHAR(rec.DATE_CREATED, ''YYYY-MM-DD"T"HH24:MI:SS''));
            APEX_JSON.write(''date_last_updated'',        TO_CHAR(rec.DATE_LAST_UPDATED, ''YYYY' || '-MM-DD"T"HH24:MI:SS''));
            APEX_JSON.write(''failed_access_attempts'',   rec.FAILED_ACCESS_ATTEMPTS);
        APEX_JSON.close_object;
    END write_user_json;

BEGIN
    IF :workspaceName IS NOT NULL THEN
        BEGIN
            SELECT workspace_id
              INTO l_ws_id_2
              FROM apex_workspace_schemas
             WHERE workspace_name = UPPER(:workspaceName);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                write_error(:status, 400, ''Workspace name not available: '' || :workspaceName);
                RETURN;
        END;
    END IF;

    IF l_input IS NOT NULL THEN
        -- Specific user requested by "WORKSPACE_ID::USERNAME"
        l_pos := INSTR(l_input, ''::'');
        IF l_pos = 0 THEN
            write_error(:status, 400, ''Invalid input format. Expected WORKSPACE_ID::USERNAME'');
            RETURN;
        END IF;

        l_ws_id_1 := TO_NUMBER(SUBSTR(l_input, 1, l_pos - 1));
        l_user_name := UPPER(SUBSTR(l_input, l_pos + 2));' || '

        IF l_ws_id_2 IS NOT NULL AND  l_ws_id_2 != l_ws_id_1 THEN
            write_error(:status, 403, ''Access denied: You are not authorized to access resources outside your subscribed workspace.'');
            RETURN;
        END IF;

        APEX_JSON.open_object;
            APEX_JSON.open_array(''items'');
                FOR rec IN (
                    SELECT * FROM apex_workspace_apex_users
                    WHERE WORKSPACE_ID = l_ws_id_1
                    AND USER_NAME = l_user_name
                ) LOOP
                    write_user_json(rec);
                END LOOP;
            APEX_JSON.close_array;
        APEX_JSON.close_object;
        :status := 200;
    ELSE
        -- Normalize pagination params
        IF l_limit > 1000 THEN
            l_limit := 1000;
        ELSIF l_limit <= 0 THEN
            l_limit := 100;
        END IF;

        IF l_offset < 0 THEN
            l_offset := 0;
        END IF;

        -- Count total matching users
        SELECT COUNT' || '(*)
          INTO l_count
          FROM apex_workspace_apex_users
         WHERE (l_ws_name IS NULL OR workspace_id = l_ws_id_2)
            AND workspace_id != 10;

        APEX_JSON.open_object;
            APEX_JSON.open_array(''items'');

                FOR rec IN (
                    SELECT * FROM apex_workspace_apex_users
                    WHERE (l_ws_name IS NULL OR workspace_id = l_ws_id_2)
                        AND workspace_id != 10
                    ORDER BY USER_NAME
                    OFFSET l_offset ROWS FETCH NEXT l_limit ROWS ONLY
                ) LOOP
                    write_user_json(rec);
                END LOOP;

            APEX_JSON.close_array;

            APEX_JSON.write(''limit'', l_limit);
            APEX_JSON.write(''offset'', l_offset);
            APEX_JSON.write(''count'', l_count);
            APEX_JSON.write(''hasMore'', (l_offset + l_limit < l_count));
        APEX_JSON.close_object;
        :status := 200;
    END IF;

EXCEPTION
    WHEN OTHERS ' || 'THEN
        ROLLBACK;
            write_error(:status, 500, ''Unexpected error: '' || SQLERRM);
END;');

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user',
      p_method             => 'GET',
      p_name               => 'X-ORDS-STATUS-CODE',
      p_bind_variable_name => 'status',
      p_source_type        => 'HEADER',
      p_param_type         => 'INT',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user',
      p_method             => 'GET',
      p_name               => 'workspaceId',
      p_bind_variable_name => 'workspaceId',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user',
      p_method             => 'GET',
      p_name               => 'limit',
      p_bind_variable_name => 'limit',
      p_source_type        => 'URI',
      p_param_type         => 'INT',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user',
      p_method             => 'GET',
      p_name               => 'offset',
      p_bind_variable_name => 'offset',
      p_source_type        => 'URI',
      p_param_type         => 'INT',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user',
      p_method             => 'GET',
      p_name               => 'id',
      p_bind_variable_name => 'id',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'user',
      p_method         => 'DELETE',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_input         VARCHAR2(200) := :id;

    l_ws_id         NUMBER;
    l_user_name     VARCHAR2(100);
    l_pos           PLS_INTEGER;


    l_ws_id_1       APEX_WORKSPACE_SCHEMAS.WORKSPACE_ID%TYPE;
    l_ws_name       VARCHAR2(100);

    PROCEDURE write_error(p_status OUT NUMBER, p_http_status NUMBER, p_message VARCHAR2) IS
    BEGIN
        APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'');
            APEX_JSON.write(''message'', p_message);
        APEX_JSON.close_object;
        p_status := p_http_status;
    END;

BEGIN
    IF :workspaceName IS NOT NULL THEN
        BEGIN
            SELECT workspace_id
              INTO l_ws_id_1
              FROM apex_workspace_schemas
             WHERE workspace_name = UPPER(:workspaceName);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                write_error(:status, 400, ''Workspace name not available: '' || :workspaceName);
                RETURN;
        END;
    END IF;

    -- Parse input: Expe' || 'ct WORKSPACE_ID::USER
    l_pos := INSTR(l_input, ''::'');
    IF l_pos = 0 THEN
        write_error(:status, 400, ''Invalid input format; expected WORKSPACE_ID::USER'');
        RETURN;
    END IF;

    BEGIN
        l_ws_id := TO_NUMBER(SUBSTR(l_input, 1, l_pos - 1));
        IF l_ws_id_1 IS NOT NULL AND  l_ws_id_1 != l_ws_id THEN
            write_error(:status, 403, ''Access denied: You are not authorized to access resources outside your subscribed workspace.'');
            RETURN;
        END IF;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            write_error(:status, 400, ''Invalid workspace_id: must be numeric'');
            RETURN;
    END;
    -- Check workspace existence including isActive 
    BEGIN
        SELECT WORKSPACE
            INTO l_ws_name
            FROM APEX_WORKSPACES
        WHERE WORKSPACE_ID = l_ws_id;

        IF l_ws_name IS NULL THEN
            write_error(:status, 400, ''Invalid workspace_id: '' || l_ws_id);
            RETURN;
        END IF;
    END;

  ' || '  l_user_name := TRIM(SUBSTR(l_input, l_pos + 2));
    IF l_user_name IS NULL THEN
        write_error(:status, 400, ''Missing user_name in input'');
        RETURN;
    END IF;

    l_user_name := UPPER(l_user_name);

    -- Set workspace context
    APEX_UTIL.SET_SECURITY_GROUP_ID(l_ws_id);

    -- Check and remove user
    IF NOT APEX_UTIL.IS_USERNAME_UNIQUE(l_user_name) THEN
        APEX_UTIL.REMOVE_USER(l_user_name);

        COMMIT;

        OPEN :items FOR
            SELECT 
                l_ws_id AS workspace_id,
                l_ws_id || ''::'' || l_user_name AS id,
                l_ws_name || ''::'' || l_user_name AS user_name,
                l_user_name AS workspace_user_name
            FROM dual;
        :status := 200;
    ELSE
        write_error(:status, 404, ''User: '' || l_user_name || '' not found in workspace: '' || l_ws_id);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        write_error(:status, 500, ''Unexpected error: '' || SQLERRM);
END;');

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user',
      p_method             => 'DELETE',
      p_name               => 'id',
      p_bind_variable_name => 'id',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user',
      p_method             => 'DELETE',
      p_name               => 'X-ORDS-STATUS-CODE',
      p_bind_variable_name => 'status',
      p_source_type        => 'HEADER',
      p_param_type         => 'INT',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user',
      p_method             => 'DELETE',
      p_name               => 'items',
      p_bind_variable_name => 'items',
      p_source_type        => 'RESPONSE',
      p_param_type         => 'RESULTSET',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user',
      p_method             => 'DELETE',
      p_name               => 'workspaceName',
      p_bind_variable_name => 'workspaceName',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'user',
      p_method         => 'POST',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_body                    CLOB := :body_text;
    l_json                    JSON_OBJECT_T;
    l_pos                     PLS_INTEGER;

    request_ws_id             NUMBER;
    request_user_name         VARCHAR2(100);
    request_split_user_name   VARCHAR2(100);
    request_first_name        VARCHAR2(255);
    request_last_name         VARCHAR2(255);
    request_email             VARCHAR2(255);
    request_password          VARCHAR2(255);
    request_description       VARCHAR2(255);

    l_ws_name                 VARCHAR2(100);
    l_ws_id                   APEX_WORKSPACE_SCHEMAS.WORKSPACE_ID%TYPE;

    -- Helper to write error JSON
    PROCEDURE write_error(p_status OUT NUMBER, p_http_status NUMBER, p_message VARCHAR2) IS
    BEGIN
        APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'');
            APEX_JSON.write(''message'', p_message);
        APEX_JSON.close_object;
        p_status := p_http_status;
    END;

BEGIN
    IF :workspaceName IS NOT NUL' || 'L THEN
        BEGIN
            SELECT workspace_id
              INTO l_ws_id
              FROM apex_workspace_schemas
             WHERE workspace_name = UPPER(:workspaceName);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                write_error(:status, 400, ''Workspace name not available: '' || :workspaceName);
                RETURN;
        END;
    END IF;

    -- Validate request body
    IF l_body IS NULL OR NVL(DBMS_LOB.GETLENGTH(l_body), 0) = 0 THEN
      write_error(:status, 400, ''Empty request body'');
      RETURN;
    END IF;

    -- Parse and extract JSON
    l_json                  := JSON_OBJECT_T.PARSE(l_body);

    request_ws_id           := l_json.get_string(''workspace_id'');
    IF l_ws_id IS NOT NULL AND  l_ws_id != TO_NUMBER(request_ws_id) THEN
        write_error(:status, 403, ''Access denied: You are not authorized to access resources outside your subscribed workspace.'');
        RETURN;
    END IF;

    request_user_name       := l_json.get_string(''' || 'user_name'');
    request_email           := l_json.get_string(''email_address'');
    request_password        := l_json.get_string(''web_password'');

    -- Extract required fields
    IF request_ws_id is NULL THEN
        write_error(:status, 400, ''Missing required field: workspaceId'');
        RETURN;
    END IF;
    IF request_user_name is NULL THEN
        write_error(:status, 400, ''Missing required field: user_name'');
        RETURN;
    END IF;
    IF request_email is NULL THEN
        write_error(:status, 400, ''Missing required field:  email_address'');
        RETURN;
    END IF;
    IF request_password is NULL THEN
        write_error(:status, 400, ''Missing required field: password'');
        RETURN;
    END IF;

    -- Validate email format
    --IF NOT REGEXP_LIKE(request_email, ''^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'', ''i'') THEN
    --    write_error(:status, 400, ''Invalid email address format.'');
    --    RETURN;
    --END IF;

    -- Check workspace existence including isAc' || 'tive 
    BEGIN
        SELECT WORKSPACE
            INTO l_ws_name
            FROM APEX_WORKSPACES
        WHERE WORKSPACE_ID = request_ws_id;

        IF l_ws_name IS NULL THEN
            write_error(:status, 400, ''Invalid workspace_id: '' || request_ws_id);
            RETURN;
        END IF;
    END;

    -- Set workspace context
    APEX_UTIL.SET_SECURITY_GROUP_ID(request_ws_id);

    l_pos := INSTR(request_user_name, ''::'');
    IF l_pos = 0 THEN
            write_error(:status, 400, ''Invalid USERNAME'');
            RETURN;
        END IF;
    request_split_user_name := SUBSTR(request_user_name, l_pos + 2);

    -- Check if username already exists
    IF NOT APEX_UTIL.IS_USERNAME_UNIQUE(request_split_user_name) THEN
        write_error(:status, 409, ''User: '' || request_split_user_name || '' already exists in workspace: '' || l_ws_name);
        RETURN;
    END IF;

    -- Optional fields
    IF l_json.has(''first_name'') THEN
        request_first_name := l_json.get_string(''first_nam' || 'e'');
    END IF;
    IF l_json.has(''last_name'') THEN
        request_last_name := l_json.get_string(''last_name'');
    END IF;
    IF l_json.has(''description'') THEN
        request_description := l_json.get_string(''description'');
    END IF;

    -- Create the user
    BEGIN
        APEX_UTIL.CREATE_USER(
            p_user_name      => request_split_user_name,
            p_first_name     => request_first_name,
            p_last_name      => request_last_name,
            p_email_address  => request_email,
            p_web_password   => request_password,
            p_description    => request_description
        );
        COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                write_error(:status, 500, ''Error creating user: '' || SQLERRM);
                RETURN;
    END;

    -- Respond with success
    OPEN :items FOR
        SELECT
            ''success'' AS status,
            request_ws_id AS workspace_id,
            request_ws_id || ''::''' || ' || request_split_user_name AS id,
            l_ws_name || ''::'' || request_split_user_name AS user_name,
            request_split_user_name AS workspace_user_name
        FROM dual;
    :status := 201;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            write_error(:status, 500, ''Unexpected error: '' || SQLERRM);
END;');

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user',
      p_method             => 'POST',
      p_name               => 'X-ORDS-STATUS-CODE',
      p_bind_variable_name => 'status',
      p_source_type        => 'HEADER',
      p_param_type         => 'INT',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user',
      p_method             => 'POST',
      p_name               => 'items',
      p_bind_variable_name => 'items',
      p_source_type        => 'RESPONSE',
      p_param_type         => 'RESULTSET',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user',
      p_method             => 'POST',
      p_name               => 'workspaceName',
      p_bind_variable_name => 'workspaceName',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'user',
      p_method         => 'PUT',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_input                     VARCHAR2(200) := :id;
    l_body                      CLOB := :body_text;
    l_json                      JSON_OBJECT_T;

    l_ws_id                     NUMBER;
    l_user_name                 VARCHAR2(100);
    l_pos                       PLS_INTEGER;
    l_user_id                   NUMBER;
    l_roles                     VARCHAR2(4000);
    l_groups                    VARCHAR2(4000);
    l_group_names               APEX_T_VARCHAR2;
    l_user                      apex_workspace_apex_users%ROWTYPE;

    request_email_address       VARCHAR2(240);
    request_first_name          VARCHAR2(255);
    request_last_name           VARCHAR2(255);
    request_description         VARCHAR2(240);
    request_account_locked      VARCHAR2(10);

    l_ws_id_1                   APEX_WORKSPACE_SCHEMAS.WORKSPACE_ID%TYPE;
    l_ws_name                   VARCHAR2(100);

    -- Helper to write error JSON
    PROCEDURE write_error(p_status OUT NUMBER, p_http_status N' || 'UMBER, p_message VARCHAR2) IS
    BEGIN
        APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'');
            APEX_JSON.write(''message'', p_message);
        APEX_JSON.close_object;
        p_status := p_http_status;
    END;

BEGIN
    IF :workspaceName IS NOT NULL THEN
        BEGIN
            SELECT workspace_id
              INTO l_ws_id_1
              FROM apex_workspace_schemas
             WHERE workspace_name = UPPER(:workspaceName);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                write_error(:status, 400, ''Workspace name not available: '' || :workspaceName);
                RETURN;
        END;
    END IF;

    -- Validate request body
    IF l_body IS NULL OR NVL(DBMS_LOB.GETLENGTH(l_body), 0) = 0 THEN
      write_error(:status, 400, ''Empty request body'');
      RETURN;
    END IF;

    -- Parse ID
    l_pos := INSTR(l_input, ''::'');
    IF l_pos = 0 THEN
        write_error(:status, 400, ''Invalid input format; expected WORKSPACE_ID::' || 'USER'');
        RETURN;
    END IF;

    BEGIN
        l_ws_id := TO_NUMBER(SUBSTR(l_input, 1, l_pos - 1));
        IF l_ws_id_1 IS NOT NULL AND  l_ws_id_1 != l_ws_id THEN
                write_error(:status, 403, ''Access denied: You are not authorized to access resources outside your subscribed workspace.'');
                RETURN;
        END IF;
    EXCEPTION
        WHEN VALUE_ERROR THEN
        write_error(:status, 400, ''Invalid workspace_id: must be numeric'');
        RETURN;
    END;
    -- Check workspace existence including isActive 
    BEGIN
        SELECT WORKSPACE
            INTO l_ws_name
            FROM APEX_WORKSPACES
        WHERE WORKSPACE_ID = l_ws_id;

        IF l_ws_name IS NULL THEN
            write_error(:status, 400, ''Invalid workspace_id: '' || l_ws_id);
            RETURN;
        END IF;
    END;
    l_user_name := UPPER(SUBSTR(l_input, l_pos + 2));

    -- Set workspace context
    APEX_UTIL.SET_SECURITY_GROUP_ID(l_ws_id);

    -- Get user info
    l_user' || '_id := APEX_UTIL.GET_USER_ID(l_user_name);
    l_roles := APEX_UTIL.GET_USER_ROLES(l_user_name);
    l_groups := APEX_UTIL.GET_GROUPS_USER_BELONGS_TO(l_user_name);

    -- Fetch DB user data
    SELECT * INTO l_user
        FROM APEX_WORKSPACE_APEX_USERS
        WHERE WORKSPACE_ID = l_ws_id AND USER_NAME = l_user_name;

    -- Parse JSON input
    l_json := JSON_OBJECT_T.PARSE(l_body);

    request_email_address := COALESCE(l_json.get_string(''email_address''), l_user.email);
    request_first_name := COALESCE(l_json.get_string(''first_name''), l_user.first_name);
    request_last_name := COALESCE(l_json.get_string(''last_name''), l_user.last_name);
    request_description := COALESCE(l_json.get_string(''description''), l_user.description);
    request_account_locked := COALESCE(l_json.get_string(''account_locked''), l_user.account_locked);

    -- Normalize account_locked
    IF request_account_locked IS NULL OR UPPER(request_account_locked) IN (''N'', ''NO'', ''FALSE'') THEN
        request_account_' || 'locked := ''N'';
    ELSIF UPPER(request_account_locked) IN (''Y'', ''YES'', ''TRUE'') THEN
        request_account_locked := ''Y'';
    ELSE
        write_error(:status, 400, ''Invalid value for account_locked: '' || request_account_locked);
        RETURN;
    END IF;

    -- Edit user
    APEX_UTIL.EDIT_USER(
        p_user_id => l_user_id,
        p_user_name => l_user.user_name,
        p_email_address => request_email_address,
        p_first_name => request_first_name,
        p_last_name => request_last_name,
        p_description => request_description,
        p_account_locked => request_account_locked,
        p_failed_access_attempts => l_user.failed_access_attempts,
        p_web_password => NULL,
        p_developer_roles => l_roles
    );

    -- Reapply groups if present
    IF l_groups IS NOT NULL THEN
        SELECT TRIM(REGEXP_SUBSTR(l_groups, ''[^,]+'', 1, LEVEL))
            BULK COLLECT INTO l_group_names
            FROM dual
        CONNECT BY LEVEL <= REGEXP_COUNT(l_groups, ' || ''','') + 1;

        APEX_UTIL.SET_GROUP_USER_GRANTS(
            p_user_name => l_user_name,
            p_granted_group_names => l_group_names
        );
    END IF;

    COMMIT;

    -- Success response
    OPEN :items FOR
        SELECT
              ''success'' AS status,
              l_ws_id AS workspace_id,
              l_ws_id || ''::'' || l_user_name AS id,
              l_ws_name || ''::'' || l_user_name AS user_name,
              l_user_name AS workspace_user_name
        FROM dual;
    :status := 200;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        write_error(:status, 404, ''User not found'');

    WHEN VALUE_ERROR THEN
        ROLLBACK;
        write_error(:status, 400, ''Invalid input value'');

    WHEN OTHERS THEN
        ROLLBACK;
        write_error(:status, 500, ''Unexpected error: '' || SQLERRM);
END;');

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user',
      p_method             => 'PUT',
      p_name               => 'items',
      p_bind_variable_name => 'items',
      p_source_type        => 'RESPONSE',
      p_param_type         => 'RESULTSET',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user',
      p_method             => 'PUT',
      p_name               => 'X-ORDS-STATUS-CODE',
      p_bind_variable_name => 'status',
      p_source_type        => 'HEADER',
      p_param_type         => 'INT',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user',
      p_method             => 'PUT',
      p_name               => 'id',
      p_bind_variable_name => 'id',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user',
      p_method             => 'PUT',
      p_name               => 'workspaceName',
      p_bind_variable_name => 'workspaceName',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'userPrivilege',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'userPrivilege',
      p_method         => 'GET',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_input             VARCHAR2(200) := :id;
    l_ws_id             NUMBER;
    l_user_name         VARCHAR2(100);
    l_pos               PLS_INTEGER;

    l_exists            BOOLEAN;
    l_roles             VARCHAR2(4000);

    l_ws_id_1           APEX_WORKSPACE_SCHEMAS.WORKSPACE_ID%TYPE;
    l_ws_name           VARCHAR2(100);

    -- Role groups as constants
    c_admin_roles        CONSTANT SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(''ADMIN'');
    c_app_dev_roles      CONSTANT SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(''CREATE'', ''EDIT'', ''MONITOR'', ''HELP'');
    c_sql_dev_roles      CONSTANT SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(''SQL'', ''DATA_LOADER'', ''MONITOR'');

    -- Output values
    c_val_admin          CONSTANT VARCHAR2(50) := ''ADMIN'';
    c_val_app_dev        CONSTANT VARCHAR2(50) := ''DEVELOPER_APP_BUILDER'';
    c_val_sql_dev        CONSTANT VARCHAR2(50) := ''DEVELOPER_SQL_WORKSHOP'';

    l_user_roles SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
    l_ou' || 'tput     SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();

    FUNCTION has_all_roles(
        p_user_roles SYS.ODCIVARCHAR2LIST,
        p_required   SYS.ODCIVARCHAR2LIST
    ) RETURN BOOLEAN IS
    BEGIN
        FOR i IN 1 .. p_required.COUNT LOOP
            DECLARE
                v_found BOOLEAN := FALSE;
            BEGIN
                FOR j IN 1 .. p_user_roles.COUNT LOOP
                    IF p_required(i) = p_user_roles(j) THEN
                        v_found := TRUE;
                        EXIT;
                    END IF;
                END LOOP;
                IF NOT v_found THEN
                    RETURN FALSE;
                END IF;
            END;
        END LOOP;
        RETURN TRUE;
    END;

    -- Helper: write error JSON
    PROCEDURE write_error(p_status OUT NUMBER, p_http_status NUMBER, p_message VARCHAR2) IS
    BEGIN
        APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'');
            APEX_JSON.write(''message'', p_message);
        ' || 'APEX_JSON.close_object;
        p_status := p_http_status;
    END;

    
BEGIN
    IF :workspaceName IS NOT NULL THEN
        BEGIN
            SELECT workspace_id
              INTO l_ws_id_1
              FROM apex_workspace_schemas
             WHERE workspace_name = UPPER(:workspaceName);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                write_error(:status, 400, ''Workspace name not available: '' || :workspaceName);
                RETURN;
        END;
    END IF;

    -- Parse and validate input
    l_pos := INSTR(l_input, ''::'');
    IF l_pos = 0 THEN
        write_error(:status, 400, ''Invalid input format; expected WORKSPACE_ID::USER'');
        RETURN;
    END IF;

    BEGIN
        l_ws_id := TO_NUMBER(SUBSTR(l_input, 1, l_pos - 1));
        IF l_ws_id_1 IS NOT NULL AND  l_ws_id_1 != l_ws_id THEN
            write_error(:status, 403, ''Access denied: You are not authorized to access resources outside your subscribed workspace.'');
            RETURN;
        EN' || 'D IF;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            write_error(:status, 400, ''Invalid workspace_id: must be numeric'');
            RETURN;
    END;
    -- Check workspace existence including isActive 
    BEGIN
        SELECT WORKSPACE
            INTO l_ws_name
            FROM APEX_WORKSPACES
        WHERE WORKSPACE_ID = l_ws_id;

        IF l_ws_name IS NULL THEN
            write_error(:status, 400, ''Invalid workspace_id: '' || l_ws_id);
            RETURN;
        END IF;
    END;

    l_user_name := TRIM(SUBSTR(l_input, l_pos + 2));

    IF l_user_name IS NULL THEN
        write_error(:status, 400, ''User name cannot be empty'');
        RETURN;
    END IF;

    l_user_name := UPPER(l_user_name);

    -- Set workspace context
    APEX_UTIL.SET_SECURITY_GROUP_ID(l_ws_id);

    -- Check if user exists
    l_exists := NOT APEX_UTIL.IS_USERNAME_UNIQUE(l_user_name);

    IF NOT l_exists THEN
        write_error(:status, 404, ''User: '' || l_user_name || '' not found in workspace:' || ' '' || l_ws_id);
        RETURN;
    END IF;

    -- Fetch user roles
    l_roles := APEX_UTIL.GET_USER_ROLES(l_user_name);

    -- Parse and output grouped roles
    IF l_roles IS NULL OR l_roles = '''' THEN
        OPEN :items FOR SELECT NULL AS id FROM dual WHERE 1 = 0;
        :status := 200;
        RETURN;
    END IF;

    -- Split l_roles into list
    FOR i IN 1 .. REGEXP_COUNT(l_roles, ''[^:]+'') + 1 LOOP
        l_user_roles.EXTEND;
        l_user_roles(l_user_roles.COUNT) := REGEXP_SUBSTR(l_roles, ''[^:]+'', 1, i);
    END LOOP;

    -- Only include if ALL roles in group are present
    IF has_all_roles(l_user_roles, c_admin_roles) THEN
        l_output.EXTEND; 
        l_output(l_output.COUNT) := c_val_admin;
    END IF;

    IF has_all_roles(l_user_roles, c_app_dev_roles) THEN
        l_output.EXTEND; 
        l_output(l_output.COUNT) := c_val_app_dev;
    END IF;

    IF has_all_roles(l_user_roles, c_sql_dev_roles) THEN
        l_output.EXTEND; 
        l_output(l_output.COUNT) ' || ':= c_val_sql_dev;
    END IF;

    -- Return output in order
    OPEN :items FOR
        SELECT COLUMN_VALUE AS id FROM TABLE(l_output);

    :status := 200;

EXCEPTION
    WHEN OTHERS THEN
        write_error(:status, 500, ''Unexpected error: '' || SQLERRM);
END;');

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'userPrivilege',
      p_method             => 'GET',
      p_name               => 'id',
      p_bind_variable_name => 'id',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'userPrivilege',
      p_method             => 'GET',
      p_name               => 'X-ORDS-STATUS-CODE',
      p_bind_variable_name => 'status',
      p_source_type        => 'HEADER',
      p_param_type         => 'INT',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'userPrivilege',
      p_method             => 'GET',
      p_name               => 'items',
      p_bind_variable_name => 'items',
      p_source_type        => 'RESPONSE',
      p_param_type         => 'RESULTSET',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'userPrivilege',
      p_method             => 'GET',
      p_name               => 'workspaceName',
      p_bind_variable_name => 'workspaceName',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'userPrivilege',
      p_method         => 'PUT',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_input              VARCHAR2(200) := :id;
    l_body               CLOB := :body_text;
    l_json               JSON_OBJECT_T;

    l_ws_id              NUMBER;
    l_user_name          VARCHAR2(100);
    l_pos                PLS_INTEGER;
    l_user_id            NUMBER;
    l_account_locked     VARCHAR2(10);
    l_roles              VARCHAR2(4000);
    l_groups             VARCHAR2(4000);
    l_group_names        APEX_T_VARCHAR2;
    l_user               apex_workspace_apex_users%ROWTYPE;

    request_privilege    VARCHAR2(50);
    request_action       VARCHAR2(10);

    l_ws_id_1            APEX_WORKSPACE_SCHEMAS.WORKSPACE_ID%TYPE;
    l_ws_name            VARCHAR2(100);
    
    l_existing_roles  SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
    l_new_privs       VARCHAR2(4000);

    -- Constants
    c_admin_roles     CONSTANT SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(''ADMIN'');
    c_app_dev_roles   CONSTANT SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(''CREATE'', ''E' || 'DIT'');
    c_sql_dev_roles   CONSTANT SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(''SQL'', ''DATA_LOADER'');

    c_val_admin       CONSTANT VARCHAR2(50) := ''ADMIN'';
    c_val_app_dev     CONSTANT VARCHAR2(50) := ''CREATE:EDIT:MONITOR:HELP'';
    c_val_sql_dev     CONSTANT VARCHAR2(50) := ''SQL:DATA_LOADER:MONITOR'';

    -- Helper: check if role exists s
    FUNCTION has_any(p_required SYS.ODCIVARCHAR2LIST, p_user SYS.ODCIVARCHAR2LIST) RETURN BOOLEAN IS
    l_found INTEGER;
    BEGIN
        IF p_user IS NULL THEN
            RETURN FALSE;
        END IF;

        FOR i IN 1 .. p_required.COUNT LOOP
            SELECT COUNT(1)
            INTO l_found
            FROM TABLE(p_user) t
            WHERE t.COLUMN_VALUE = p_required(i);

            IF l_found > 0 THEN
                RETURN TRUE;
            END IF;
        END LOOP;

        RETURN FALSE;
    END;

    PROCEDURE edit_user_roles(p_priv VARCHAR2) IS
    BEGIN
        APEX_UTIL.EDIT_USER(
            p_user_id                => l' || '_user_id,
            p_user_name              => l_user_name,
            p_default_schema         => l_user.first_schema_provisioned,
            p_email_address          => l_user.email,
            p_first_name             => l_user.first_name,
            p_last_name              => l_user.last_name,
            p_description            => l_user.description,
            p_account_locked         => l_account_locked,
            p_failed_access_attempts => l_user.failed_access_attempts,
            p_developer_roles        => p_priv,
            -- p_web_password           => l_user.web_password,
            p_change_password_on_first_use => ''N''
        );
    END;
    
    -- Helper: write error JSON
    PROCEDURE write_error(p_status OUT NUMBER, p_http_status NUMBER, p_message VARCHAR2) IS
    BEGIN
        APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''error'');
        APEX_JSON.write(''message'', p_message);
        APEX_JSON.close_object;
        p_status := p_http_st' || 'atus;
    END;
BEGIN
    IF :workspaceName IS NOT NULL THEN
        BEGIN
            SELECT workspace_id
              INTO l_ws_id_1
              FROM apex_workspace_schemas
             WHERE workspace_name = UPPER(:workspaceName);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                write_error(:status, 400, ''Workspace name not available: '' || :workspaceName);
                RETURN;
        END;
    END IF;

    -- Validate request body
    IF l_body IS NULL OR NVL(DBMS_LOB.GETLENGTH(l_body), 0) = 0 THEN
        write_error(:status, 400, ''Empty request body'');
        RETURN;
    END IF;

    -- Validate ID format
    l_pos := INSTR(l_input, ''::'');
    IF l_pos = 0 THEN
        write_error(:status, 400, ''Invalid input format; expected WORKSPACE_ID::USER'');
        RETURN;
    END IF;

    -- Parse workspace ID + username
    BEGIN
        l_ws_id := TO_NUMBER(SUBSTR(l_input, 1, l_pos - 1));
        IF l_ws_id_1 IS NOT NULL AND  l_ws_id_1 != l_ws_id THEN
         ' || '   write_error(:status, 403, ''Access denied: You are not authorized to access resources outside your subscribed workspace.'');
            RETURN;
        END IF;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            write_error(:status, 400, ''Invalid workspace_id: must be numeric'');
            RETURN;
    END;
    -- Check workspace existence including isActive 
    BEGIN
        SELECT WORKSPACE
            INTO l_ws_name
            FROM APEX_WORKSPACES
        WHERE WORKSPACE_ID = l_ws_id;

        IF l_ws_name IS NULL THEN
            write_error(:status, 400, ''Invalid workspace_id: '' || l_ws_id);
            RETURN;
        END IF;
    END;

    l_user_name := UPPER(SUBSTR(l_input, l_pos + 2));

    -- Set workspace context
    APEX_UTIL.SET_SECURITY_GROUP_ID(l_ws_id);

    -- Get user details
    l_user_id := APEX_UTIL.GET_USER_ID(l_user_name);
    l_roles   := APEX_UTIL.GET_USER_ROLES(l_user_name);
    l_groups  := APEX_UTIL.GET_GROUPS_USER_BELONGS_TO(l_user_name);

    SELEC' || 'T * INTO l_user
      FROM APEX_WORKSPACE_APEX_USERS
     WHERE WORKSPACE_ID = l_ws_id
       AND USER_NAME = l_user_name;

    -- Normalize account_locked value
    IF UPPER(NVL(l_user.account_locked, ''N'')) IN (''Y'', ''YES'', ''TRUE'') THEN
        l_account_locked := ''Y'';
    ELSE
        l_account_locked := ''N'';
    END IF;

    -- Parse request JSON
    l_json := JSON_OBJECT_T.PARSE(l_body);
    
    request_privilege := UPPER(l_json.get_string(''privilege''));
    IF request_privilege IS NULL THEN
        write_error(:status, 400, ''Missing privilege'');
        RETURN;
    END IF;

    IF request_privilege NOT IN (''ADMIN'', ''DEVELOPER_APP_BUILDER'', ''DEVELOPER_SQL_WORKSHOP'') THEN
        write_error(:status, 400, ''Invalid privilege: Please provide a valid privilege'');
        RETURN;
    END IF;

    request_action := UPPER(l_json.get_string(''action''));
    IF request_action IS NULL THEN
        write_error(:status, 400, ''Missing action'');
        RETURN;
    END IF;

    IF request_action ' || 'NOT IN (''ADD'', ''REMOVE'') THEN
        write_error(:status, 400, ''Invalid action: Please provide a valid action ADD/REMOVE'');
        RETURN;
    END IF;

    -- Modify roles
    IF l_roles IS NOT NULL THEN
        FOR i IN 1 .. REGEXP_COUNT(l_roles, ''[^:]+'') + 1 LOOP
            l_existing_roles.EXTEND;
            l_existing_roles(l_existing_roles.COUNT) := REGEXP_SUBSTR(l_roles, ''[^:]+'', 1, i);
        END LOOP;
    END IF;

    -- ADD Privilege logic
    IF request_action = ''ADD'' THEN
        IF request_privilege = ''ADMIN'' THEN
            IF NOT has_any(c_admin_roles, l_existing_roles) THEN
                edit_user_roles(c_val_admin);
            ELSE
                write_error(:status, 400, ''Privilege assignment failed: the specified privilege is already assigned to the user.'');
                RETURN;
            END IF;

        ELSIF request_privilege = ''DEVELOPER_APP_BUILDER'' THEN
            IF NOT has_any(c_admin_roles, l_existing_roles) AND NOT has_any(c_app_dev_roles, l_' || 'existing_roles) THEN
                l_new_privs := c_val_app_dev;
                IF has_any(c_sql_dev_roles, l_existing_roles) THEN
                    l_new_privs := l_new_privs || '':'' || c_val_sql_dev;
                END IF;
                edit_user_roles(l_new_privs);
            ELSE
                write_error(:status, 400, ''Privilege assignment failed: the specified privilege is already assigned to the user.'');
                RETURN;
            END IF;

        ELSIF request_privilege = ''DEVELOPER_SQL_WORKSHOP'' THEN
            IF NOT has_any(c_admin_roles, l_existing_roles) AND NOT has_any(c_sql_dev_roles, l_existing_roles) THEN
                l_new_privs := c_val_sql_dev;
                IF has_any(c_app_dev_roles, l_existing_roles) THEN
                    l_new_privs := c_val_app_dev || '':'' || l_new_privs;
                END IF;
                edit_user_roles(l_new_privs);
            ELSE
                write_error(:status, 400, ''Privilege assignment failed: the sp' || 'ecified privilege is already assigned to the user.'');
                RETURN;
            END IF;
        END IF;

    -- REMOVE Privilege logic
    ELSIF request_action = ''REMOVE'' THEN
        IF request_privilege = ''ADMIN'' THEN
            IF has_any(c_admin_roles, l_existing_roles) THEN
                l_new_privs := '''';
                IF has_any(c_app_dev_roles, l_existing_roles) THEN
                    l_new_privs := c_val_app_dev;
                END IF;
                IF has_any(c_sql_dev_roles, l_existing_roles) THEN
                    IF l_new_privs IS NOT NULL THEN
                        l_new_privs := l_new_privs || '':'' || c_val_sql_dev;
                    ELSE
                        l_new_privs := c_val_sql_dev;
                    END IF;
                END IF;
                edit_user_roles(l_new_privs);
            ELSE
                write_error(:status, 400, ''Privilege removal failed: the specified privilege is not assigned to the user.'');
                RET' || 'URN;
            END IF;

        ELSIF request_privilege = ''DEVELOPER_APP_BUILDER'' THEN
            IF has_any(c_admin_roles, l_existing_roles) THEN
                write_error(:status, 400, ''Privilege removal failed: Workspace Administrator privilege is active.'');
                RETURN;
            ELSIF has_any(c_app_dev_roles, l_existing_roles) THEN
                IF has_any(c_sql_dev_roles, l_existing_roles) THEN
                    edit_user_roles(c_val_sql_dev);
                ELSE
                    edit_user_roles(NULL);
                END IF;
            ELSE
                write_error(:status, 400, ''Privilege removal failed: the specified privilege is not assigned to the user.'');
                RETURN;
            END IF;

        ELSIF request_privilege = ''DEVELOPER_SQL_WORKSHOP'' THEN
            IF has_any(c_admin_roles, l_existing_roles) THEN
                write_error(:status, 400, ''Privilege removal failed: Workspace Administrator privilege is active.'');
       ' || '         RETURN;
            ELSIF has_any(c_sql_dev_roles, l_existing_roles) THEN
                IF has_any(c_app_dev_roles, l_existing_roles) THEN
                    edit_user_roles(c_val_app_dev);
                ELSE
                    edit_user_roles(NULL);
                END IF;
            ELSE
                write_error(:status, 400, ''Privilege removal failed: the specified privilege is not assigned to the user.'');
                RETURN;
            END IF;
        END IF;
    END IF;

    -- Reapply groups (if any)
    IF l_groups IS NOT NULL THEN
        SELECT TRIM(REGEXP_SUBSTR(l_groups, ''[^,]+'', 1, LEVEL))
          BULK COLLECT INTO l_group_names
          FROM dual
        CONNECT BY LEVEL <= REGEXP_COUNT(l_groups, '','') + 1;

        APEX_UTIL.SET_GROUP_USER_GRANTS(
            p_user_name => l_user_name,
            p_granted_group_names => l_group_names
        );
    END IF;

    COMMIT;

    -- Success JSON
    APEX_JSON.open_object;
        APEX_JSON.write(''st' || 'atus'', ''success'');
        APEX_JSON.write(''workspace_id'', l_ws_id);
        APEX_JSON.write(''id'', l_ws_id || ''::'' || l_user_name);
        APEX_JSON.write(''user_name'', l_ws_name || ''::'' || l_user_name);
        APEX_JSON.write(''workspace_user_name'', l_user_name);
    APEX_JSON.close_object;
    :status := 200;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        write_error(:status, 404, ''User not found'');

    WHEN VALUE_ERROR THEN
        ROLLBACK;
        write_error(:status, 400, ''Invalid input value'');

    WHEN OTHERS THEN
        ROLLBACK;
        write_error(:status, 500, ''Unexpected error: '' || SQLERRM);
END;');

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'userPrivilege',
      p_method             => 'PUT',
      p_name               => 'items',
      p_bind_variable_name => 'items',
      p_source_type        => 'RESPONSE',
      p_param_type         => 'RESULTSET',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'userPrivilege',
      p_method             => 'PUT',
      p_name               => 'X-ORDS-STATUS-CODE',
      p_bind_variable_name => 'status',
      p_source_type        => 'HEADER',
      p_param_type         => 'INT',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'userPrivilege',
      p_method             => 'PUT',
      p_name               => 'id',
      p_bind_variable_name => 'id',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'userPrivilege',
      p_method             => 'PUT',
      p_name               => 'workspaceName',
      p_bind_variable_name => 'workspaceName',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'userGroup',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'userGroup',
      p_method         => 'GET',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_input             VARCHAR2(200) := :id;
    l_user_name         VARCHAR2(100);
    l_ws_id             NUMBER;
    l_pos               PLS_INTEGER;

    l_exists            BOOLEAN;
    l_groups            VARCHAR2(4000);

    l_ws_id_1           APEX_WORKSPACE_SCHEMAS.WORKSPACE_ID%TYPE;
    l_group_names       APEX_T_VARCHAR2;

    -- Helper to output consistent error JSON
    PROCEDURE write_error(p_status OUT NUMBER, p_http_status NUMBER, p_message VARCHAR2) IS
    BEGIN
        APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'');
            APEX_JSON.write(''message'', p_message);
        APEX_JSON.close_object;
        p_status := p_http_status;
    END;
BEGIN
    IF :workspaceName IS NOT NULL THEN
        BEGIN
            SELECT workspace_id
              INTO l_ws_id_1
              FROM apex_workspace_schemas
             WHERE workspace_name = UPPER(:workspaceName);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                write_erro' || 'r(:status, 400, ''Workspace name not available: '' || :workspaceName);
                RETURN;
        END;
    END IF;

    -- Split and validate input
    l_pos := INSTR(l_input, ''::'');
    IF l_pos = 0 THEN
        write_error(:status, 400, ''Invalid input format; expected WORKSPACE_ID::USER'');
        RETURN;
    END IF;

    BEGIN
        l_ws_id := TO_NUMBER(SUBSTR(l_input, 1, l_pos - 1));
        IF l_ws_id_1 IS NOT NULL AND  l_ws_id_1 != l_ws_id THEN
            write_error(:status, 403, ''Access denied: You are not authorized to access resources outside your subscribed workspace.'');
            RETURN;
        END IF;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            write_error(:status, 400, ''Invalid workspace_id: must be numeric'');
            RETURN;
    END;
    l_user_name := TRIM(SUBSTR(l_input, l_pos + 2));

    IF l_user_name IS NULL THEN
        write_error(:status, 400, ''User name cannot be empty'');
        RETURN;
    END IF;

    l_user_name := UPPER(l_user_name)' || ';

    -- Set workspace context
    APEX_UTIL.SET_SECURITY_GROUP_ID(l_ws_id);

    -- Check if user exists
    l_exists := NOT APEX_UTIL.IS_USERNAME_UNIQUE(l_user_name);

    IF NOT l_exists THEN
        write_error(:status, 404, ''User: '' || l_user_name || '' not found in workspace '' || l_ws_id);
        RETURN;
    END IF;

    -- Fetch groups
    l_groups := APEX_UTIL.GET_GROUPS_USER_BELONGS_TO(l_user_name);

    -- Return groups (or empty)
    IF l_groups IS NULL OR l_groups = '''' THEN
        OPEN :items FOR
            SELECT NULL AS id FROM dual WHERE 1 = 0;  -- always empty
        RETURN;
    END IF;

    -- Convert comma-separated to APEX_T_VARCHAR2 array
    SELECT TRIM(REGEXP_SUBSTR(l_groups, ''[^,]+'', 1, LEVEL))
    BULK COLLECT INTO l_group_names
    FROM dual
    CONNECT BY LEVEL <= REGEXP_COUNT(l_groups, '','') + 1;

    -- Return group list with resolved workspace_id (specific or global 10)
    OPEN :items FOR
        SELECT 
            CASE
                WHEN EXISTS (
  ' || '                  SELECT 1 FROM apex_workspace_groups 
                     WHERE group_name = column_value 
                       AND workspace_id = l_ws_id
                ) THEN l_ws_id || ''::'' || column_value
                ELSE ''10::'' || column_value
            END AS id
        FROM TABLE(l_group_names);


    :status := 200;

EXCEPTION
    WHEN OTHERS THEN
        write_error(:status, 500, ''Unexpected error: '' || SQLERRM);
END;');

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'userGroup',
      p_method             => 'GET',
      p_name               => 'id',
      p_bind_variable_name => 'id',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'userGroup',
      p_method             => 'GET',
      p_name               => 'X-ORDS-STATUS-CODE',
      p_bind_variable_name => 'status',
      p_source_type        => 'HEADER',
      p_param_type         => 'INT',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'userGroup',
      p_method             => 'GET',
      p_name               => 'items',
      p_bind_variable_name => 'items',
      p_source_type        => 'RESPONSE',
      p_param_type         => 'RESULTSET',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'userGroup',
      p_method             => 'GET',
      p_name               => 'workspaceName',
      p_bind_variable_name => 'workspaceName',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'userGroup',
      p_method         => 'PUT',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_input              VARCHAR2(200) := :id;
    l_body               CLOB := :body_text;
    l_json               JSON_OBJECT_T;

    l_ws_id              NUMBER;
    l_user_name          VARCHAR2(100);
    l_pos                PLS_INTEGER;
    l_user_id            NUMBER;
    l_groups             VARCHAR2(4000);
    l_group_names        APEX_T_VARCHAR2;

    request_ws_id        NUMBER;
    request_group        VARCHAR2(100);
    request_action       VARCHAR2(10);

    c_action_add         CONSTANT VARCHAR2(10) := ''ADD'';
    c_action_remove      CONSTANT VARCHAR2(10) := ''REMOVE'';

    l_ws_id_1            APEX_WORKSPACE_SCHEMAS.WORKSPACE_ID%TYPE;
    l_ws_name            VARCHAR2(100);

    -- Helper: write error JSON
    PROCEDURE write_error(p_status OUT NUMBER, p_http_status NUMBER, p_message VARCHAR2) IS
    BEGIN
        APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'');
            APEX_JSON.write(''message'', p_message);
        APEX_JSON.close_obje' || 'ct;
        p_status := p_http_status;
    END;

    -- Helper: check if role exists
    FUNCTION has_group(p_groups APEX_T_VARCHAR2, p_group VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        IF p_groups IS NULL OR p_groups.COUNT = 0 OR p_group IS NULL THEN
            RETURN FALSE;
        END IF;

        FOR i IN 1 .. p_groups.COUNT LOOP
            IF UPPER(p_groups(i)) = UPPER(p_group) THEN
                RETURN TRUE;
            END IF;
        END LOOP;
        RETURN FALSE;
    END;

    -- Helper: remove group from array
    FUNCTION remove_group(p_groups APEX_T_VARCHAR2, p_group VARCHAR2) RETURN APEX_T_VARCHAR2 IS
        l_result APEX_T_VARCHAR2;
    BEGIN
        l_result := APEX_T_VARCHAR2();
        FOR i IN 1 .. p_groups.COUNT LOOP
            IF p_groups.EXISTS(i) THEN
                IF UPPER(p_groups(i)) != UPPER(p_group) THEN
                    l_result.EXTEND;
                    l_result(l_result.COUNT) := p_groups(i);
                END IF;
            END IF;
    ' || '    END LOOP;
        RETURN l_result;
    END;

BEGIN
    IF :workspaceName IS NOT NULL THEN
        BEGIN
            SELECT workspace_id
              INTO l_ws_id_1
              FROM apex_workspace_schemas
             WHERE workspace_name = UPPER(:workspaceName);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                write_error(:status, 400, ''Workspace name not available: '' || :workspaceName);
                RETURN;
        END;
    END IF;

    -- Validate request body
    IF l_body IS NULL OR NVL(DBMS_LOB.GETLENGTH(l_body), 0) = 0 THEN
        write_error(:status, 400, ''Empty request body'');
        RETURN;
    END IF;

    -- Validate ID format
    l_pos := INSTR(l_input, ''::'');
    IF l_pos = 0 THEN
        write_error(:status, 400, ''Invalid input format; expected WORKSPACE_ID::USER'');
        RETURN;
    END IF;

    -- Parse workspace ID + username
    BEGIN
        l_ws_id := TO_NUMBER(SUBSTR(l_input, 1, l_pos - 1));
        IF l_ws_id_1 IS NOT NULL AND  l' || '_ws_id_1 != l_ws_id THEN
            write_error(:status, 403, ''Access denied: You are not authorized to access resources outside your subscribed workspace.'');
            RETURN;
        END IF;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            write_error(:status, 400, ''Invalid workspace_id: must be numeric'');
            RETURN;
    END;
    -- Check workspace existence 
    BEGIN
        SELECT WORKSPACE
            INTO l_ws_name
            FROM APEX_WORKSPACES
        WHERE WORKSPACE_ID = l_ws_id;

        IF l_ws_name IS NULL THEN
            write_error(:status, 400, ''Invalid workspace_id: '' || l_ws_id);
            RETURN;
        END IF;
    END;
    l_user_name := TRIM(SUBSTR(l_input, l_pos + 2));

    IF l_user_name IS NULL THEN
        write_error(:status, 400, ''Missing user name'');
        RETURN;
    END IF;

    l_user_name := UPPER(l_user_name);

    -- Set workspace context
    APEX_UTIL.SET_SECURITY_GROUP_ID(l_ws_id);

    -- Get user ID
    l_user_id := APEX_' || 'UTIL.GET_USER_ID(l_user_name);
    IF l_user_id IS NULL THEN
        write_error(:status, 404, ''User: '' || l_user_name || '' not found in workspace: '' || l_ws_id);
        RETURN;
    END IF;

    -- Get user''s current groups
    l_groups := APEX_UTIL.GET_GROUPS_USER_BELONGS_TO(l_user_name);

    -- Parse JSON
    l_json := JSON_OBJECT_T.PARSE(l_body);
    request_group := l_json.get_string(''group'');
    request_action := UPPER(l_json.get_string(''action''));

    IF request_group IS NULL THEN
        write_error(:status, 400, ''Missing group'');
        RETURN;
    END IF;
    -- Validate ID format
    l_pos := INSTR(request_group, ''::'');
    IF l_pos = 0 THEN
        write_error(:status, 400, ''Invalid group value'');
        RETURN;
    END IF;
    request_ws_id := TO_NUMBER(SUBSTR(request_group, 1, l_pos - 1));
    IF request_ws_id != l_ws_id AND request_ws_id != 10 THEN
        write_error(:status, 403, ''Access denied: You are only authorized to access resources within your subscribed wo' || 'rkspace: '' || l_ws_name || '' or the global (INTERNAL) workspace.'');
        RETURN;
    END IF;

    request_group := TRIM(SUBSTR(request_group, l_pos + 2));


    -- Validate group existence
    DECLARE
        l_group_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO l_group_count
        FROM APEX_WORKSPACE_GROUPS
        WHERE WORKSPACE_ID in (l_ws_id, 10) AND UPPER(GROUP_NAME) = UPPER(request_group);

        IF l_group_count = 0 THEN
            write_error(:status, 400, ''Group: '' || request_group || '' does not exist in workspace'');
            RETURN;
        END IF;
    END;

    -- Convert group list to array
    IF l_groups IS NOT NULL THEN
        SELECT TRIM(REGEXP_SUBSTR(l_groups, ''[^,]+'', 1, LEVEL))
        BULK COLLECT INTO l_group_names
        FROM dual
        CONNECT BY LEVEL <= REGEXP_COUNT(l_groups, '','') + 1;
    ELSE
        l_group_names := APEX_T_VARCHAR2();
    END IF;

    -- Apply action
    IF request_action = c_action_add THEN
        IF has_group(l_grou' || 'p_names, request_group) THEN
            write_error(:status, 400, ''Group: '' || request_group || '' is already assigned.'');
            RETURN;
        ELSE
            l_group_names.EXTEND;
            l_group_names(l_group_names.COUNT) := request_group;
        END IF;
    ELSIF request_action = c_action_remove THEN
        IF NOT has_group(l_group_names, request_group) THEN
            write_error(:status, 400, ''Group: '' || request_group || '' is not assigned.'');
            RETURN;
        ELSE
            l_group_names := remove_group(l_group_names, request_group);
        END IF;
    ELSE
        write_error(:status, 400, ''Invalid action: '' || request_action || ''. Allowed: ADD or REMOVE.'');
        RETURN;
    END IF;

    -- Apply group grants
    APEX_UTIL.SET_GROUP_USER_GRANTS(
        p_user_name => l_user_name,
        p_granted_group_names => l_group_names
    );

    COMMIT;

    -- Success
    APEX_JSON.open_object;
        APEX_JSON.write(''status'', ''success'');
        APEX' || '_JSON.write(''workspace_id'', l_ws_id);
        APEX_JSON.write(''id'', l_ws_id || ''::'' || l_user_name);
        APEX_JSON.write(''user_name'', l_ws_name || ''::'' || l_user_name);
        APEX_JSON.write(''workspace_user_name'', l_user_name);
    APEX_JSON.close_object;
    :status := 200;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        write_error(:status, 404, ''User not found'');
    WHEN VALUE_ERROR THEN
        ROLLBACK;
        write_error(:status, 400, ''Invalid input value'');
    WHEN OTHERS THEN
        ROLLBACK;
        write_error(:status, 500, ''Unexpected error'');
END;');

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'userGroup',
      p_method             => 'PUT',
      p_name               => 'id',
      p_bind_variable_name => 'id',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'userGroup',
      p_method             => 'PUT',
      p_name               => 'X-ORDS-STATUS-CODE',
      p_bind_variable_name => 'status',
      p_source_type        => 'HEADER',
      p_param_type         => 'INT',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'userGroup',
      p_method             => 'PUT',
      p_name               => 'items',
      p_bind_variable_name => 'items',
      p_source_type        => 'RESPONSE',
      p_param_type         => 'RESULTSET',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'userGroup',
      p_method             => 'PUT',
      p_name               => 'workspaceName',
      p_bind_variable_name => 'workspaceName',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'user/changePassword',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);

  ORDS.DEFINE_HANDLER(
      p_module_name    => 'oracle.ag',
      p_pattern        => 'user/changePassword',
      p_method         => 'PUT',
      p_source_type    => 'plsql/block',
      p_mimes_allowed  => NULL,
      p_comments       => NULL,
      p_source         => 
'DECLARE
    l_input                     VARCHAR2(200) := :id;
    l_body                      CLOB := :body_text;
    l_json                      JSON_OBJECT_T;

    l_ws_id                     NUMBER;
    l_user_name                 VARCHAR2(100);
    l_pos                       PLS_INTEGER;
    l_user_id                   NUMBER;
    l_account_locked            VARCHAR2(10);
    l_roles                     VARCHAR2(4000);
    l_groups                    VARCHAR2(4000);
    l_group_names               APEX_T_VARCHAR2;
    l_user                      apex_workspace_apex_users%ROWTYPE;

    request_new_password        VARCHAR2(255);

    l_ws_id_1                   APEX_WORKSPACE_SCHEMAS.WORKSPACE_ID%TYPE;
    l_ws_name                   VARCHAR2(100);

    -- Helper to write error JSON
    PROCEDURE write_error(p_status OUT NUMBER, p_http_status NUMBER, p_message VARCHAR2) IS
    BEGIN
        APEX_JSON.open_object;
            APEX_JSON.write(''status'', ''error'');
            APEX_JSON.' || 'write(''message'', p_message);
        APEX_JSON.close_object;
        p_status := p_http_status;
    END;

BEGIN
    IF :workspaceName IS NOT NULL THEN
        BEGIN
            SELECT workspace_id
              INTO l_ws_id_1
              FROM apex_workspace_schemas
             WHERE workspace_name = UPPER(:workspaceName);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                write_error(:status, 400, ''Workspace name not available: '' || :workspaceName);
                RETURN;
        END;
    END IF;

    -- Validate request body
    IF l_body IS NULL OR NVL(DBMS_LOB.GETLENGTH(l_body), 0) = 0 THEN
        write_error(:status, 400, ''Empty request body'');
        RETURN;
    END IF;

    -- Parse ID
    l_pos := INSTR(l_input, ''::'');
    IF l_pos = 0 THEN
        write_error(:status, 400, ''Invalid input format; expected WORKSPACE_ID::USER'');
        RETURN;
    END IF;

    BEGIN
        l_ws_id := TO_NUMBER(SUBSTR(l_input, 1, l_pos - 1));
        IF l_ws_id_1 IS NOT N' || 'ULL AND  l_ws_id_1 != l_ws_id THEN
            write_error(:status, 403, ''Access denied: You are not authorized to access resources outside your subscribed workspace.'');
            RETURN;
        END IF;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            write_error(:status, 400, ''Invalid workspace_id: must be numeric'');
            RETURN;
    END;
    -- Check workspace existence 
    BEGIN
        SELECT WORKSPACE
            INTO l_ws_name
            FROM APEX_WORKSPACES
        WHERE WORKSPACE_ID = l_ws_id;

        IF l_ws_name IS NULL THEN
            write_error(:status, 400, ''Invalid workspace_id: '' || l_ws_id);
            RETURN;
        END IF;
    END;
    l_user_name := UPPER(SUBSTR(l_input, l_pos + 2));

    -- Set workspace context
    APEX_UTIL.SET_SECURITY_GROUP_ID(l_ws_id);

    -- Get user info
    l_user_id := APEX_UTIL.GET_USER_ID(l_user_name);
    l_roles := APEX_UTIL.GET_USER_ROLES(l_user_name);
    l_groups := APEX_UTIL.GET_GROUPS_USER_BELONGS_TO(l_user' || '_name);

    -- Fetch DB user data
    SELECT * INTO l_user
        FROM APEX_WORKSPACE_APEX_USERS
        WHERE WORKSPACE_ID = l_ws_id AND USER_NAME = l_user_name;

    -- Parse JSON input
    l_json := JSON_OBJECT_T.PARSE(l_body);

     -- Fetch values from request body
    IF l_json.has(''web_password'') THEN
        request_new_password := l_json.get_string(''web_password'');
    END IF;

    -- Normalize account_locked
    l_account_locked := l_user.account_locked;
    IF l_account_locked IS NULL OR UPPER(l_account_locked) IN (''N'', ''NO'', ''FALSE'') THEN
        l_account_locked := ''N'';
    ELSIF UPPER(l_account_locked) IN (''Y'', ''YES'', ''TRUE'') THEN
        l_account_locked := ''Y'';
    ELSE
        write_error(:status, 400, ''Invalid value for account_locked: '' || l_account_locked);
        RETURN;
    END IF;

    -- Edit user
    APEX_UTIL.EDIT_USER(
        p_user_id                   => l_user_id,
        p_user_name                 => l_user_name,
        p_email_address             =' || '> l_user.email,
        p_first_name                => l_user.first_name,
        p_last_name                 => l_user.last_name,
        p_description               => l_user.description,
        p_account_locked            => l_account_locked,
        p_account_expiry            => l_user.account_expiry,
        p_failed_access_attempts    => l_user.failed_access_attempts,
        p_web_password              => request_new_password,
        p_new_password              => request_new_password,
        p_developer_roles           => l_roles
    );

    -- Reapply groups if present
    IF l_groups IS NOT NULL THEN
        SELECT TRIM(REGEXP_SUBSTR(l_groups, ''[^,]+'', 1, LEVEL))
            BULK COLLECT INTO l_group_names
            FROM dual
        CONNECT BY LEVEL <= REGEXP_COUNT(l_groups, '','') + 1;

        APEX_UTIL.SET_GROUP_USER_GRANTS(
            p_user_name => l_user_name,
            p_granted_group_names => l_group_names
        );
    END IF;

    COMMIT;

    -- Success re' || 'sponse
    OPEN :items FOR
        SELECT
              ''success'' AS status,
              l_ws_id AS workspace_id,
              l_ws_id || ''::'' || l_user_name AS id,
              l_ws_name || ''::'' || l_user_name AS user_name,
              l_user_name AS workspace_user_name
        FROM dual;
    :status := 200;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        write_error(:status, 404, ''User not found'');

    WHEN VALUE_ERROR THEN
        ROLLBACK;
        write_error(:status, 400, ''Invalid input value'');

    WHEN OTHERS THEN
        ROLLBACK;
        write_error(:status, 500, ''Unexpected error: '' || SQLERRM);
END;');

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user/changePassword',
      p_method             => 'PUT',
      p_name               => 'items',
      p_bind_variable_name => 'items',
      p_source_type        => 'RESPONSE',
      p_param_type         => 'RESULTSET',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user/changePassword',
      p_method             => 'PUT',
      p_name               => 'X-ORDS-STATUS-CODE',
      p_bind_variable_name => 'status',
      p_source_type        => 'HEADER',
      p_param_type         => 'INT',
      p_access_method      => 'OUT',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user/changePassword',
      p_method             => 'PUT',
      p_name               => 'id',
      p_bind_variable_name => 'id',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  ORDS.DEFINE_PARAMETER(
      p_module_name        => 'oracle.ag',
      p_pattern            => 'user/changePassword',
      p_method             => 'PUT',
      p_name               => 'workspaceName',
      p_bind_variable_name => 'workspaceName',
      p_source_type        => 'URI',
      p_param_type         => 'STRING',
      p_access_method      => 'IN',
      p_comments           => NULL);

  l_modules(1) := 'oracle.ag';

  ORDS.DEFINE_PRIVILEGE(
      p_privilege_name => 'oracle.ag',
      p_roles          => l_roles,
      p_patterns       => l_patterns,
      p_modules        => l_modules,
      p_label          => 'Oracle AG Privilege',
      p_description    => 'privilege',
      p_comments       => NULL); 

  l_roles.DELETE;
  l_modules.DELETE;
  l_patterns.DELETE;


COMMIT;

END;