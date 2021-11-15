#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2019,2021 Oracle and/or its affiliates.
#
# Since: January, 2019
# Author: sanjay.singh@oracle.com,  paramdeep.saini@oracle.com
# Description:
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

chmod 666 /etc/sudoers
echo "orcladmin       ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
chmod 440 /etc/sudoers
