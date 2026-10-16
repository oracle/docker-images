#!/bin/bash
# Copyright 2020, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# MAINTAINER <paramdeep.saini@oracle.com>
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# ------------------------------------------------------------
chmod ug+x $SCRIPT_DIR/*.sh && \
yum -y install oracle-database-preinstall-19c net-tools which zip unzip tar openssl openssh-server openssh-client vim-minimal which vim-minimal passwd sudo python36 && \
yum clean all
