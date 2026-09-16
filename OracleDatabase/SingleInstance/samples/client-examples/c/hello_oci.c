/*
 * Query Oracle AI Database through the OCI C API.
 *
 * Set ORACLE_USER and ORACLE_PASSWORD before running this example.  The
 * optional ORACLE_CONNECT_STRING defaults to localhost:1521/FREEPDB1.
 */

#include <oci.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int check_status(sword status, OCIError *errhp, const char *operation)
{
    OraText error_message[512];
    sb4 error_code = 0;

    if (status == OCI_SUCCESS || status == OCI_SUCCESS_WITH_INFO) {
        return 0;
    }

    if (errhp != NULL) {
        OCIErrorGet(errhp, 1, NULL, &error_code, error_message,
                    sizeof(error_message), OCI_HTYPE_ERROR);
        fprintf(stderr, "%s failed: ORA-%05d: %s\n", operation,
                error_code, error_message);
    } else {
        fprintf(stderr, "%s failed with OCI status %d\n", operation,
                status);
    }
    return -1;
}

int main(void)
{
    const char *user = getenv("ORACLE_USER");
    const char *password = getenv("ORACLE_PASSWORD");
    const char *connect_string = getenv("ORACLE_CONNECT_STRING");
    const char *sql = "SELECT banner FROM v$version";
    OCIEnv *envhp = NULL;
    OCIError *errhp = NULL;
    OCISvcCtx *svchp = NULL;
    OCIStmt *stmthp = NULL;
    OCIDefine *defnp = NULL;
    OraText banner[1024];
    sword status;
    int logged_on = 0;
    int exit_code = EXIT_FAILURE;

    if (connect_string == NULL) {
        connect_string = "localhost:1521/FREEPDB1";
    }

    if (user == NULL || password == NULL) {
        fprintf(stderr, "Set ORACLE_USER and ORACLE_PASSWORD first.\n");
        return EXIT_FAILURE;
    }

    status = OCIEnvCreate(&envhp, OCI_THREADED | OCI_OBJECT, NULL, NULL,
                          NULL, NULL, 0, NULL);
    if (check_status(status, NULL, "OCIEnvCreate") != 0) {
        goto cleanup;
    }

    status = OCIHandleAlloc(envhp, (void **)&errhp, OCI_HTYPE_ERROR, 0, NULL);
    if (check_status(status, errhp, "OCIHandleAlloc(OCIError)") != 0) {
        goto cleanup;
    }

    status = OCILogon(envhp, errhp, &svchp,
                      (OraText *)user, (ub4)strlen(user),
                      (OraText *)password, (ub4)strlen(password),
                      (OraText *)connect_string,
                      (ub4)strlen(connect_string));
    if (check_status(status, errhp, "OCILogon") != 0) {
        goto cleanup;
    }
    logged_on = 1;

    status = OCIHandleAlloc(envhp, (void **)&stmthp, OCI_HTYPE_STMT, 0, NULL);
    if (check_status(status, errhp, "OCIHandleAlloc(OCIStmt)") != 0) {
        goto cleanup;
    }

    status = OCIStmtPrepare(stmthp, errhp, (OraText *)sql,
                            (ub4)strlen(sql), OCI_NTV_SYNTAX, OCI_DEFAULT);
    if (check_status(status, errhp, "OCIStmtPrepare") != 0) {
        goto cleanup;
    }

    status = OCIDefineByPos(stmthp, &defnp, errhp, 1, banner,
                            sizeof(banner), SQLT_STR, NULL, NULL, NULL,
                            OCI_DEFAULT);
    if (check_status(status, errhp, "OCIDefineByPos") != 0) {
        goto cleanup;
    }

    status = OCIStmtExecute(svchp, stmthp, errhp, 0, 0, NULL, NULL,
                            OCI_DEFAULT);
    if (check_status(status, errhp, "OCIStmtExecute") != 0) {
        goto cleanup;
    }

    for (;;) {
        memset(banner, 0, sizeof(banner));
        status = OCIStmtFetch2(stmthp, errhp, 1, OCI_FETCH_NEXT, 0,
                               OCI_DEFAULT);
        if (status == OCI_NO_DATA) {
            break;
        }
        if (check_status(status, errhp, "OCIStmtFetch2") != 0) {
            goto cleanup;
        }
        puts((char *)banner);
    }

    exit_code = EXIT_SUCCESS;

cleanup:
    if (stmthp != NULL) {
        OCIHandleFree(stmthp, OCI_HTYPE_STMT);
    }
    if (logged_on) {
        OCILogoff(svchp, errhp);
    }
    if (errhp != NULL) {
        OCIHandleFree(errhp, OCI_HTYPE_ERROR);
    }
    if (envhp != NULL) {
        OCIHandleFree(envhp, OCI_HTYPE_ENV);
    }
    return exit_code;
}
