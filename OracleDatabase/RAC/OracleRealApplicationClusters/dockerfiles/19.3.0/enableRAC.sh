#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Enable RAC feature in Oracle Software
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

source /home/oracle/.bashrc
make -f $DB_HOME/rdbms/lib/ins_rdbms.mk rac_on
make -f $DB_HOME/rdbms/lib/ins_rdbms.mk ioracle
