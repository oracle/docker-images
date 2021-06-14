#!/bin/bash -e
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

SCRIPT_DIR=$(cd $(dirname $0); pwd)

echo "Starting SQL Server"
/opt/mssql/bin/sqlservr & 
pid=$!

# Configure the database in the background
${SCRIPT_DIR}/configure-db.sh
wait $pid
