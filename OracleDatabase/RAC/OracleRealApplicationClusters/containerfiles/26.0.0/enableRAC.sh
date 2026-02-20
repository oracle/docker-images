#!/bin/bash
# shellcheck disable=SC2034,SC2166,SC2155,SC1090,SC2046,SC2178,SC2207,SC2163,SC2115,SC2173,SC1091,SC1143,SC2164,SC3014
# LICENSE UPL 1.0
#
# Copyright (c) 2018,2021 Oracle and/or its affiliates.
#
# Since: January, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Enable RAC feature in Oracle Software
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

source /home/"${DB_USER}"/.bashrc

export ORACLE_HOME=${DB_HOME}
export PATH=${ORACLE_HOME}/bin:/bin:/sbin:/usr/bin
export LD_LIBRARY_PATH=${ORACLE_HOME}/lib:/lib:/usr/lib

make -f "$DB_HOME"/rdbms/lib/ins_rdbms.mk rac_on
make -f "$DB_HOME"/rdbms/lib/ins_rdbms.mk ioracle
