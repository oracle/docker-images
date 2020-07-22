#!/bin/bash

# Remove not needed components
rm -rf $ORACLE_HOME/apex
rm -rf $ORACLE_HOME/jdbc
# ZDLRA installer files
rm -rf $ORACLE_HOME/lib/ra*.zip
rm -rf $ORACLE_HOME/ords
rm -rf $ORACLE_HOME/sqldeveloper
rm -rf $ORACLE_HOME/ucp
# as we won't install patches
rm -rf $ORACLE_HOME/lib/*.a
find $ORACLE_HOME -name '*.a' -type f -delete
# OUI backup
rm -rf $ORACLE_HOME/inventory/backup/*
# Network tools help
rm -rf $ORACLE_HOME/network/tools/help/mgr/help_*
# Temp location
rm -rf /tmp/* 
# Advised by Gerald Venzl
echo "Cleanup Advised by Gerald Venzl"
rm -rf $ORACLE_HOME/.patch_storage/*
rm -rf $ORACLE_HOME/R/*
rm -rf $ORACLE_HOME/assistants/*
rm -rf $ORACLE_HOME/cfgtoollogs/*
rm -rf $ORACLE_HOME/dmu/*
rm -rf $ORACLE_HOME/inventory/*
rm -rf $ORACLE_HOME/javavm/*
rm -rf $ORACLE_HOME/md/*
rm -rf $ORACLE_HOME/suptools/*
echo "Additional Cleanup by Jacek Gebal"
#additional cleanup- removes 1.2GB of DB-sources size - for small images only (no Java)
rm -rf $ORACLE_HOME/OPatch/              #OPatch --> Patching
rm -rf $ORACLE_HOME/crs/                 #crs --> some clusterware single instance failover things
rm -rf $ORACLE_HOME/ctx/                 #ctx --> Oracle Text (also used for JSON index)
rm -rf $ORACLE_HOME/cv/                  #cv --> some patchign related stuff I think
rm -rf $ORACLE_HOME/has/                 #has --> no clue
rm -rf $ORACLE_HOME/jdk/                 #jdk --> Java jdk
rm -rf $ORACLE_HOME/jlib/                #jlib --> Java libraries
rm -rf $ORACLE_HOME/mgw/                 #mgw --> Message gateway
rm -rf $ORACLE_HOME/odbc/                #odbc --> ODBC
rm -rf $ORACLE_HOME/olap/                #olap --> OLAP
rm -rf $ORACLE_HOME/ord/                 #ord --> Multimedia I think
rm -rf $ORACLE_HOME/oui/                 #oui --> Oracle Universal installer
rm -rf $ORACLE_HOME/owm/                 #owm --> Workspace manger
rm -rf $ORACLE_HOME/perl/                #perl --> perl
rm -rf $ORACLE_HOME/precomp/             #precomp --> Not much clue either
rm -rf $ORACLE_HOME/sdk/                 #sdk --> some more java I believe
rm -rf $ORACLE_HOME/sqlpatch/            #sqlpatch --> patching related stuff
rm -rf $ORACLE_HOME/usm/                 #usm --> Universal storage management
rm -rf $ORACLE_HOME/rdbms/admin/cdb_cloud
rm -rf $ORACLE_HOME/rdbms/xml/em
rm -rf $ORACLE_HOME/relnotes
find $ORACLE_HOME -name '*.zip' -type f -delete
find $ORACLE_HOME -name '*.txt' -type f -delete
find $ORACLE_HOME -name '*O' -type f -delete
find $ORACLE_HOME -path '*/install/*' -delete
find $ORACLE_HOME -name 'install' -type d -delete

