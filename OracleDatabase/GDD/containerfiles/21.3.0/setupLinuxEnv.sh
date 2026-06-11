#!/bin/bash
#
# LICENSE UPL 1.0
# Since: November, 2020
# Author: paramdeep.saini@oracle.com
# Description: Build script for building RAC container image
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
# Copyright (c) 2020,2021 Oracle and/or its affiliates.
#
chmod ug+x $SCRIPT_DIR/*.sh && \
yum -y install oracle-database-preinstall-21c  net-tools which zip unzip tar openssl openssh-server openssh-client vim-minimal which vim-minimal passwd sudo  && \
yum clean all
