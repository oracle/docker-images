#!/bin/bash
# Copyright 2020, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# MAINTAINER <paramdeep.saini@oracle.com>

# Create Directories
mkdir -p $GSM_BASE
mkdir -p $GSM_HOME
mkdir -p $INVENTORY

chown -R oracle:oinstall $INVENTORY
chown -R oracle:oinstall $GSM_BASE
chown -R oracle:oinstall $GSM_HOME
chown -R oracle:oinstall $INSTALL_SCRIPTS
chmod 775 $INSTALL_SCRIPTS

install -d -m 0750 /etc/sudoers.d
printf '%s\n' 'oracle ALL=(grid) NOPASSWD: /bin/*, /usr/bin/*, /u01/app/*/bin/*' > /etc/sudoers.d/gdd-grid
chmod 440 /etc/sudoers.d/gdd-grid

echo "export ORACLE_HOME=$GSM_HOME" >> /home/oracle/.bashrc
echo "export PATH=$GSM_PATH" >> /home/oracle/.bashrc
echo "export LD_LIBRARY_PATH=$GSM_LD_LIBRARY_PATH" >> /home/oracle/.bashrc
echo "export SCRIPT_DIR=$SCRIPT_DIR" >> /home/oracle/.bashrc
echo "export GSM_HOME=$GSM_HOME" >> /home/oracle/.bashrc
