#!/bin/bash
# Copyright (c) 2023 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
set -eu  # Exit on error
set -o pipefail  # Fail a pipe if any sub-command fails.

###########################################################
# Global constants
STAGING_HOME=/opt/oracle-mgmtagent-staging
BOOTSTRAP_HOME=/opt/oracle/bootstrap

[ ! -d "$BOOTSTRAP_HOME" ] && mkdir "$BOOTSTRAP_HOME"
[ ! -d "$BOOTSTRAP_HOME/logs" ] && mkdir "$BOOTSTRAP_HOME/logs"
[ ! -d "$BOOTSTRAP_HOME/packages" ] && mkdir "$BOOTSTRAP_HOME/packages"
[ ! -d "$BOOTSTRAP_HOME/scripts" ] && mkdir "$BOOTSTRAP_HOME/scripts"

cp "$STAGING_HOME/scripts/watchdog.sh" "$BOOTSTRAP_HOME/scripts/"
cp "$STAGING_HOME/scripts/common.sh" "$BOOTSTRAP_HOME/scripts/"
cp "$STAGING_HOME/scripts/install_zip.sh" "$BOOTSTRAP_HOME/scripts/"
cp "$STAGING_HOME/scripts/init-agent.sh" "$BOOTSTRAP_HOME/scripts/"
chmod 744 "$BOOTSTRAP_HOME/scripts"/*

cp "$STAGING_HOME/packages/oracle.mgmt_agent.zip" "$BOOTSTRAP_HOME/packages"

"$BOOTSTRAP_HOME/scripts/watchdog.sh"
