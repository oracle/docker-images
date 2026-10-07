#!/bin/bash -e
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

if [ -x "/opt/mssql-tools18/bin/sqlcmd" ]; then
   SQLCMD="/opt/mssql-tools18/bin/sqlcmd -C"
elif [ -x "/opt/mssql-tools/bin/sqlcmd" ]; then
   SQLCMD="/opt/mssql-tools/bin/sqlcmd"
else
   SQLCMD="sqlcmd"
fi

$SQLCMD -S localhost -U sa -P "${SA_PASSWORD}" -Q "SELECT 1" || exit 1
