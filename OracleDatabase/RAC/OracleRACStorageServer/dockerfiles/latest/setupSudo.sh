#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: November, 2018
# Author: paramdeep.saini@oracle.com, sanjay.singh@oracle.com
# Description:  setup the sudo for Oracle user
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

chmod 666 /etc/sudoers
echo "oracle       ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
chmod 440 /etc/sudoers
