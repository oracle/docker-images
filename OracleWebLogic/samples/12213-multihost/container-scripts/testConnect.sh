#!/bin/bash
#
# Copyright (c) 2014-2015 Oracle and/or its affiliates. All rights reserved.
#

echo "Testing connection to Admin Server"

# Wait for AdminServer to become available for any subsequent operation
/u01/oracle/waitForAdminServer.sh

  wlst /u01/oracle/test-connect.py

