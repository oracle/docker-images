#!/bin/bash
# shellcheck disable=SC2034
# LICENSE UPL 1.0
#
# Copyright (c) 2018,2021 Oracle and/or its affiliates.
#
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Sets up the unix environment for Grid installation.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

EDITION=$1

# Create Directories
if [ "${SLIMMING}x" != 'truex' ] ; then
      mkdir -p "$GRID_BASE"
      mkdir -p "$GRID_HOME"
fi

groupadd -g 54334 asmadmin
groupadd -g 54335 asmdba
groupadd -g 54336 asmoper
useradd -u 54332 -g oinstall -G oinstall,asmadmin,asmdba,asmoper,racdba,dba  "${GRID_USER}"

install -d -m 0750 /etc/sudoers.d
# Keep allowlist narrow, but include every command Grid/DB scripts invoke via sudo
# (orainstRoot.sh, home root.sh, crsctl/srvctl). Missing entries break add-node
# and delete-node over SSH as the grid/oracle users.
cat > /etc/sudoers.d/rac-users <<EOF
Cmnd_Alias RAC_ROOT = /usr/bin/systemctl, /bin/systemctl, /usr/bin/crontab, /usr/bin/mkdir, /bin/mkdir, /usr/bin/cp, /bin/cp, /usr/bin/chown, /bin/chown, /usr/bin/chmod, /bin/chmod, /usr/bin/rm, /bin/rm, /usr/bin/rpm, /bin/rpm, /usr/sbin/chpasswd, /usr/bin/kill, /bin/kill, /usr/bin/tee, /bin/tee, ${GRID_HOME}/root.sh, ${INVENTORY}/orainstRoot.sh, ${GRID_HOME}/bin/crsctl, ${GRID_HOME}/bin/srvctl, ${DB_HOME}/root.sh
${DB_USER} ALL=(root) NOPASSWD: RAC_ROOT
${GRID_USER} ALL=(root) NOPASSWD: RAC_ROOT
EOF
chmod 440 /etc/sudoers.d/rac-users
# Drop legacy broad grants from /etc/sudoers if a prior layer added them.
sed -i \
  -e "/^${DB_USER}[[:space:]]\\+ALL=(ALL)[[:space:]]\\+NOPASSWD:[[:space:]]\\+ALL$/d" \
  -e "/^${GRID_USER}[[:space:]]\\+ALL=(ALL)[[:space:]]\\+NOPASSWD:[[:space:]]\\+ALL$/d" \
  /etc/sudoers

if [ "${SLIMMING}x" != 'truex' ] ; then
      chown -R "${GRID_USER}":oinstall "$GRID_BASE"
      chown -R "${GRID_USER}":oinstall "$GRID_HOME"
      mkdir -p "$INVENTORY"
      chown -R "${GRID_USER}":oinstall "$INVENTORY"
      echo "export PATH=$GRID_PATH" >> /home/"${GRID_USER}"/.bashrc
      echo "export LD_LIBRARY_PATH=$GRID_LD_LIBRARY_PATH" >> /home/"${GRID_USER}"/.bashrc
      echo "export SCRIPT_DIR=$SCRIPT_DIR" >> /home/"${GRID_USER}"/.bashrc
      echo "export GRID_HOME=$GRID_HOME" >> /home/"${GRID_USER}"/.bashrc
      echo "export GRID_BASE=$GRID_BASE" >> /home/"${GRID_USER}"/.bashrc
      echo "export DB_HOME=$DB_HOME" >> /home/"${GRID_USER}"/.bashrc
fi
