#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2018-2025 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

chmod 666 /etc/sudoers
echo "orcladmin       ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
chmod 440 /etc/sudoers
