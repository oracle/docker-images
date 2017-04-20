#!/bin/bash
if [ -z "$SQL" ];then exit 0; fi

cd ~/instantclient
source setenv.sh

if [ "$DBA_MODE" = y ];then
  sqlplus -S $DBA_USER/$DBA_PASSWD@//$DB_CONNSTR as sysdba <<!
$SQL
!
else
  sqlplus -S $DB_TSAM_USER/$DB_TSAM_PASSWD@//$DB_CONNSTR <<!
$SQL
!
fi
