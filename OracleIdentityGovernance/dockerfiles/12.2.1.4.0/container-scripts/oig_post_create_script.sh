#!/bin/bash
# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# This script sets OIM FE URL and runs OIM Offline Config actions post creation of domain via WDT

# invoke wlst to set FE URL
cd /u01/oracle/oracle_common/bin || exit 1
wlst.sh -skipWLSModuleScanning /u01/oracle/dockertools/set_feurl.py -frontEndHost "$FRONTENDHOST" -frontEndHttpPort "$FRONTENDPORT" -domainHome "$DOMAIN_HOME"
retval=$?
if [ $retval -ne 0 ];
 then
   echo "ERROR: Something wrong while setting Front end URL. Please check the logs"
   exit 4
fi


# invoke offine config manager
export JAVA_HOME=/usr/java/latest
chmod a+rx /u01/oracle/idm/server/bin/offlineConfigManager.sh
cd /u01/oracle/idm/server/bin/ || exit 1
offlineCmd="./offlineConfigManager.sh"
${offlineCmd}
retval=$?
if [ $retval -ne 0 ];
 then
   echo "ERROR: Offline config command failed. Please check the logs"
   exit 4
fi


# invoke the command to remove the unnessary templates in the domain config
sed -i 's/<server-template>//g' "$DOMAIN_HOME"/config/config.xml
sed -i 's/<listen-port>7100<\/listen-port>//g' "$DOMAIN_HOME"/config/config.xml
sed -i 's/<\/server-template>//g' "$DOMAIN_HOME"/config/config.xml
sed -i 's/<name>soa-server-template<\/name>//g' "$DOMAIN_HOME"/config/config.xml
sed -i 's/<name>oim-server-template<\/name>//g' "$DOMAIN_HOME"/config/config.xml
sed -i 's/<name>wsm-cache-server-template<\/name>//g' "$DOMAIN_HOME"/config/config.xml
sed -i 's/<name>wsmpm-server-template<\/name>//g' "$DOMAIN_HOME"/config/config.xml
sed -i 's/<ssl>/<!--ssl>/g' "$DOMAIN_HOME"/config/config.xml
sed -i 's/<\/ssl>/<\/ssl-->/g' "$DOMAIN_HOME"/config/config.xml

if [ ! -f /u01/oracle/idm/server/ConnectorDefaultDirectory/ConnectorConfigTemplate.xml ] && [ -d /u01/oracle/idm/server/ConnectorDefaultDirectory_orig ]; then
    cp /u01/oracle/idm/server/ConnectorDefaultDirectory_orig/ConnectorConfigTemplate.xml /u01/oracle/idm/server/ConnectorDefaultDirectory
fi
if [ ! -f /u01/oracle/idm/server/ConnectorDefaultDirectory/ConnectorSchema.xsd ] && [ -d /u01/oracle/idm/server/ConnectorDefaultDirectory_orig ]; then
    cp /u01/oracle/idm/server/ConnectorDefaultDirectory_orig/ConnectorSchema.xsd /u01/oracle/idm/server/ConnectorDefaultDirectory
fi
if [ ! -f /u01/oracle/idm/server/ConnectorDefaultDirectory/readme.txt ] && [ -d /u01/oracle/idm/server/ConnectorDefaultDirectory_orig ]; then
    cp /u01/oracle/idm/server/ConnectorDefaultDirectory_orig/readme.txt /u01/oracle/idm/server/ConnectorDefaultDirectory
fi
if [ ! -d /u01/oracle/idm/server/ConnectorDefaultDirectory/targetsystems-lib ] && [ -d /u01/oracle/idm/server/ConnectorDefaultDirectory_orig ]; then
    cp -rf /u01/oracle/idm/server/ConnectorDefaultDirectory_orig/targetsystems-lib /u01/oracle/idm/server/ConnectorDefaultDirectory
fi

