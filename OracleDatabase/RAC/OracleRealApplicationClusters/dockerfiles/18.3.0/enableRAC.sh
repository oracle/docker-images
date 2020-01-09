#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Enable RAC feature in Oracle Software
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

source /home/${DB_USER}/.bashrc

export ORACLE_HOME=${DB_HOME}
export PATH=${ORACLE_HOME}/bin:/bin:/sbin:/usr/bin
export LD_LIBRARY_PATH=${ORACLE_HOME}/lib:/lib:/usr/lib

make -f $DB_HOME/rdbms/lib/ins_rdbms.mk rac_on
make -f $DB_HOME/rdbms/lib/ins_rdbms.mk ioracle
