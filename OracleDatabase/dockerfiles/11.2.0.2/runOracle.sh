#!/bin/bash

lsnrctl start
sqlplus / as sysdba <<EOF
startup;
EXEC DBMS_XDB.SETLISTENERLOCALACCESS(FALSE);
EOF

tail -f $ORACLE_BASE/diag/rdbms/*/*/trace/alert*.log
