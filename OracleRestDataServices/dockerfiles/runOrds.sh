#!/bin/bash
# 
# Since: June, 2017
# Author: gerald.venzl@oracle.com
# Description: Setup and runs Oracle Rest Data Services.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2014-2022 Oracle and/or its affiliates. All rights reserved.
# 

CONTEXT_ROOT=${CONTEXT_ROOT:-"ords"}
CONTEXT_ROOT=$(echo "${CONTEXT_ROOT}" | sed 's/\///g')
if [ "$CONTEXT_ROOT" != "ords" ]; then
  if mv $ORDS_HOME/ords.war $ORDS_HOME/$CONTEXT_ROOT.war; then
    echo "INFO: Renamed ords.war to $CONTEXT_ROOT.war"
  else
    echo "ERROR: Failed renaming ords.war to $CONTEXT_ROOT.war. Exiting..."
    exit 1
  fi
fi

function setupOrds() {

  # Check whether the Oracle DB password has been specified
  if [ "$ORACLE_PWD" == "" ]; then
    echo "Error: No ORACLE_PWD specified!"
    echo "Please specify Oracle DB password using the ORACLE_PWD environment variable."
    exit 1;
  fi;

  # Defaults
  ORACLE_SERVICE=${ORACLE_SERVICE:-"ORCLPDB1"}
  ORACLE_HOST=${ORACLE_HOST:-"localhost"}
  ORACLE_PORT=${ORACLE_PORT:-"1521"}
  ORDS_PWD=${ORDS_PWD:-"oracle"}
  APEXI=${APEXI:-"$ORDS_HOME/doc_root/i"}
  
  # Make standalone dir
  mkdir -p $ORDS_HOME/config/$CONTEXT_ROOT/standalone
  
  # Copy template files
  cp $ORDS_HOME/$CONFIG_PROPS $ORDS_HOME/params/ords_params.properties
  cp $ORDS_HOME/$STANDALONE_PROPS $ORDS_HOME/config/$CONTEXT_ROOT/standalone/standalone.properties

  # Replace DB related variables (ords_params.properties)
  sed -i -e "s|###ORACLE_SERVICE###|$ORACLE_SERVICE|g" $ORDS_HOME/params/ords_params.properties
  sed -i -e "s|###ORACLE_HOST###|$ORACLE_HOST|g" $ORDS_HOME/params/ords_params.properties
  sed -i -e "s|###ORACLE_PORT###|$ORACLE_PORT|g" $ORDS_HOME/params/ords_params.properties
  sed -i -e "s|###ORDS_PWD###|$ORDS_PWD|g" $ORDS_HOME/params/ords_params.properties
  sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" $ORDS_HOME/params/ords_params.properties
  
  # Replace standalone runtime variables (standalone.properties)
  sed -i -e "s|###PORT###|8443|g" $ORDS_HOME/config/$CONTEXT_ROOT/standalone/standalone.properties
  sed -i -e "s|###HOST###|$HOSTNAME|g" $ORDS_HOME/config/$CONTEXT_ROOT/standalone/standalone.properties
  sed -i -e "s|###CONTEXT_ROOT###|$CONTEXT_ROOT|g" $ORDS_HOME/config/$CONTEXT_ROOT/standalone/standalone.properties
  sed -i -e "s|###DOC_ROOT###|$ORDS_HOME/doc_root|g" $ORDS_HOME/config/$CONTEXT_ROOT/standalone/standalone.properties
  sed -i -e "s|###APEXI###|$APEXI|g" $ORDS_HOME/config/$CONTEXT_ROOT/standalone/standalone.properties
   
   # Start ODRDS setup
   java -jar $ORDS_HOME/$CONTEXT_ROOT.war install simple
}

############# MAIN ################

# Check whether ords is already setup
if [ ! -f $ORDS_HOME/config/$CONTEXT_ROOT/standalone/standalone.properties ]; then
   setupOrds;
fi;

if [ "$1" = "--setuponly" ];then
  exit 0
else
  java -jar $ORDS_HOME/$CONTEXT_ROOT.war standalone
fi
