#!/bin/bash

lsnrctl start
sqlplus / as sysdba <<EOF
startup;
EOF

tail -f $ORACLE_BASE/diag/rdbms/*/*/trace/alert*.log
