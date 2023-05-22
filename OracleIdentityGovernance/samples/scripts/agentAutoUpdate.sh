#!/bin/sh
#
# Copyright (c) 2023 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: OIG Development
#
# Description: Script for upgrading agent
#
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

cd "$1" || exit
if [ -d "$1"/newpackage ]
then
    echo "There is already an upgrade in progress. Skipping this."
    exit
else
    echo "Starting Auto upgrade Process..."
fi
mkdir -p newpackage || true

cd newpackage || exit
#Download upgrade cli
wget https://objectstorage.us-ashburn-1.oraclecloud.com/p/fFvMAmluNZpv4P5dCzH7VsyJUYra5AMxhLiBSOa3AZuul4KtycxDuJtyUyWaweU4/n/idjypktnxhrf/b/agcs_ido_agent_updater/o/idm-agcs-agent-cli-upgrade.jar

#Get Agent Package
agentVersion=$(unzip -q -c  "$1"/data/agent/agent-lcm/idm-agcs-agent-lcm.jar META-INF/MANIFEST.MF | grep "Agent-Version: " | awk '{print $2}' | tr -d '\n' | tr -d '\r')
if [ -f "$1"/cacerts ]
 then
   java \
   -Djavax.net.ssl.trustStore="$1"/cacerts \
   -Djavax.net.ssl.trustStorePassword=changeit \
   -DidoConfig.logDir="$1"/newpackage\
   -DidoConfig.metricsDir="$1"/newpackage \
   -DidoConfig.walletDir="$1"/newpackage \
   -DidoConfig.workDir="$1"/newpackage \
   -cp idm-agcs-agent-cli-upgrade.jar \
   com.oracle.idm.agcs.agent.cli.AgentUpdateMain \
   --config "$1"/data/conf/config.json \
   ido autoRunUpdate \
   -ip "$1" \
   -co "$1"/data/conf/config.properties \
   -cv "$agentVersion"
 else
   java \
   -DidoConfig.logDir="$1"/data/logs \
   -DidoConfig.metricsDir="$1"/newpackage \
   -DidoConfig.walletDir="$1"/newpackage \
   -DidoConfig.workDir="$1"/newpackage \
   -cp idm-agcs-agent-cli-upgrade.jar \
   com.oracle.idm.agcs.agent.cli.AgentUpdateMain \
   --config "$1"/data/conf/config.json \
   ido autoRunUpdate \
   -ip "$1" \
   -co "$1"/data/conf/config.properties \
   -cv "$agentVersion"
fi

# shellcheck disable=SC2181
if [  "$?" = "0" ]
   then
     if [ -f "$1"/cacerts ]
      then
        mkdir "$1"/upgrade/
        cp "$1"/cacerts "$1"/upgrade/
     fi
     if [ -f "$1"/data/conf/config.properties ]
           then
             curl https://raw.githubusercontent.com/oracle/docker-images/main/OracleIdentityGovernance/samples/scripts/agentManagement.sh -o agentManagement.sh;  \
             sh agentManagement.sh --volume "$1" --agentpackage agent-package.zip \
             --config "$1"/data/conf/config.properties \
             --internalUpgrade
           else
             curl https://raw.githubusercontent.com/oracle/docker-images/main/OracleIdentityGovernance/samples/scripts/agentManagement.sh -o agentManagement.sh;  \
             sh agentManagement.sh --volume "$1" --agentpackage agent-package.zip \
             --internalUpgrade
     fi
fi

rm -rf "$1"/newpackage