#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2024 Oracle and/or its affiliates. All rights reserved.
#
# Since: July, 2017
# Author: gerald.venzl@oracle.com
# Description: Runs user shell and SQL scripts
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

SCRIPTS_ROOT="$1";

# Check whether parameter has been passed on
if [ -z "$SCRIPTS_ROOT" ]; then
   echo "$0: No SCRIPTS_ROOT passed on, no scripts will be run";
   exit 1;
fi;

# Execute custom provided files (only if directory exists and has files in it)
if [ -d "$SCRIPTS_ROOT" ] && [ -n "$(ls -A "$SCRIPTS_ROOT")" ]; then

  echo "";
  echo "Executing user defined scripts"

  for f in "$SCRIPTS_ROOT"/*; do
      case "$f" in
          *.sh)     echo "$0: running $f"; 
                    # shellcheck source=/dev/null
                    . "$f" ;;
          *.sql)    echo "$0: running $f"; echo "exit" | "$ORACLE_HOME"/bin/sqlplus -s "/ as sysdba" @"$f"; echo ;;
          *)        echo "$0: ignoring $f" ;;
      esac
      echo "";
  done
  
  echo "DONE: Executing user defined scripts"
  echo "";

fi;
