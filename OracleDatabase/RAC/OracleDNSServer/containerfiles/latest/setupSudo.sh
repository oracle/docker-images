#!/bin/bash
#
#############################
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################
#
# Description: Sets up the unix environment for DB installation.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

install -d -m 0750 /etc/sudoers.d
printf '%s\n' 'orcladmin ALL=(root) NOPASSWD: /usr/bin/kill, /opt/scripts/startup/configDNSServer.sh' > /etc/sudoers.d/dns-user
chmod 440 /etc/sudoers.d/dns-user
