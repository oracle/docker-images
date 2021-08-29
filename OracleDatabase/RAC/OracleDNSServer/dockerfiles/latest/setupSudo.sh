#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2021 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2021
# Author: paramdeep.saini@oracle.com
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

chmod 666 /etc/sudoers
echo "orcladmin       ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
chmod 440 /etc/sudoers
