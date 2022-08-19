#!/bin/bash

# Copyright (c) 2022 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

if [ $# -ne 5 ]; then
  echo usage: wait_for_db.sh oracle_home username host port service
  echo password is provided on stdin
  exit 1
fi

ORACLE_HOME=$1
DB_USERNAME=$2
DB_HOST=$3
DB_PORT=$4
DB_SERVICE=$5
DB_PASSWORD=$(cat)

MW_HOME=$ORACLE_HOME
. $ORACLE_HOME/oracle_common/common/bin/commEnv.sh

echo "Waiting for DB"
until java -cp $WEBLOGIC_CLASSPATH utils.dbping ORACLE_THIN "$DB_USERNAME as sysdba" $DB_PASSWORD $DB_HOST:$DB_PORT/$DB_SERVICE > /dev/null
do
  echo "Waiting for DB"
  sleep 10
done
echo "DB is available"

