#!/bin/bash

 # Auto generate ORACLE PWD
ORACLE_PWD=`openssl rand -hex 8`
echo "ORACLE AUTO GENERATED PASSWORD FOR SYS and SYSTEM: $ORACLE_PWD";

sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" $ORACLE_BASE/$CONFIG_RSP && \
/etc/init.d/oracle-xe configure responseFile=$ORACLE_BASE/$CONFIG_RSP

# Listener 
echo "LISTENER = \
  (DESCRIPTION_LIST = \
    (DESCRIPTION = \
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC_FOR_XE)) \
      (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)) \
    ) \
  ) \
\
" > $ORACLE_HOME/network/admin/listener.ora

echo "DEDICATED_THROUGH_BROKER_LISTENER=ON"  >> $ORACLE_HOME/network/admin/listener.ora && \
echo "DIAG_ADR_ENABLED = off"  >> $ORACLE_HOME/network/admin/listener.ora;


su -p oracle -c "sqlplus / as sysdba <<EOF
EXEC DBMS_XDB.SETLISTENERLOCALACCESS(FALSE);
EOF"

tail -f $ORACLE_BASE/diag/rdbms/*/*/trace/alert*.log
