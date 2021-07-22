#!/bin/bash
# Copyright (c) 2020,2021 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
function validate_parameter {
  name=$1
  value=$2
  if [ -z $value ]
  then
    echo "ERROR: Please set '$name' in configmap."
    echo ""       
    exit 1
  fi
}

if [ -z ${KEEP_CONTAINER_ALIVE} ]
then
   # by default we always keep this flag ON
   export KEEP_CONTAINER_ALIVE="true"
fi

if [ -z ${CONFIGURE_ES_CONNECTION} ]
then
   # by default we always keep this flag ON
   export CONFIGURE_ES_CONNECTION="true"
fi

# validate admin server parameters
validate_parameter "ADMIN_SERVER_CONTAINER_NAME" $ADMIN_SERVER_CONTAINER_NAME
validate_parameter "ADMIN_PORT" $ADMIN_PORT
validate_parameter "ADMIN_USERNAME" $ADMIN_USERNAME
validate_parameter "ADMIN_PASSWORD" $ADMIN_PASSWORD

# validate elasticsearch server parameters
validate_parameter "SEARCH_APP_USERNAME" $SEARCH_APP_USERNAME
validate_parameter "SEARCH_APP_USER_PASSWORD" $SEARCH_APP_USER_PASSWORD

export ADMIN_SERVER_CONTAINER_NAME=$ADMIN_SERVER_CONTAINER_NAME
export ADMIN_PORT=$ADMIN_PORT
export ADMIN_USERNAME=$ADMIN_USERNAME
export ADMIN_PASSWORD=$ADMIN_PASSWORD
export DOMAIN_NAME='wcp-domain'
export SEARCH_APP_USERNAME=$SEARCH_APP_USERNAME
export SEARCH_APP_USER_PASSWORD=$SEARCH_APP_USER_PASSWORD
export ES_CLUSTER_NAME='wcp_search_cluster'
export CONFIGURE_ES_CONNECTION=$CONFIGURE_ES_CONNECTION
export SEARCH_CONNECTION_NAME='wcp_es'
export SEARCH_INDEX_ALIAS_NAME='wcp_search'
export KEEP_CONTAINER_ALIVE=$KEEP_CONTAINER_ALIVE
export UNICAST_HOST_LIST=$UNICAST_HOST_LIST
export NODE_NAME=${NODE_NAME}
export LOAD_BALANCER_IP=${LOAD_BALANCER_IP}
echo "Environment variables"
echo "====================="
echo ""
echo "ADMIN_SERVER_CONTAINER_NAME=${ADMIN_SERVER_CONTAINER_NAME}"
echo "ADMIN_PORT=${ADMIN_PORT}"
echo "ADMIN_USERNAME=${ADMIN_USERNAME}"
echo "DOMAIN_NAME=${DOMAIN_NAME}"
echo "SEARCH_APP_USERNAME=${SEARCH_APP_USERNAME}"
echo "ES_CLUSTER_NAME=${ES_CLUSTER_NAME}"
echo "CONFIGURE_ES_CONNECTION=${CONFIGURE_ES_CONNECTION}"
echo "SEARCH_CONNECTION_NAME=${SEARCH_CONNECTION_NAME}"
echo "SEARCH_INDEX_ALIAS_NAME=${SEARCH_INDEX_ALIAS_NAME}"
echo "KEEP_CONTAINER_ALIVE=${KEEP_CONTAINER_ALIVE}"
echo "UNICAST_HOST_LIST=${UNICAST_HOST_LIST}"
echo "NODE_NAME=${NODE_NAME}"
echo "LOAD_BALANCER_IP=${LOAD_BALANCER_IP}"
echo ""
echo ""
 
# set the required values
export vol_name=u01
export HOST_NAME=`hostname -I`
export SERVER_NAME=Elasticsearch_Server
export ORACLE_HOME=/$vol_name/oracle
export FMW_CONFIG_HOME=$ORACLE_HOME/user_projects/domains/$DOMAIN_NAME/config/fmwconfig
export ES_CONFIG_FILE=$ORACLE_HOME/wcportal/es/installES.properties
export ES_INSTALL_FILE=$ORACLE_HOME/wcportal/es/installES.py
export CONTAINERCONFIG_LOG_DIR="/$vol_name/esHome/esNode/logs"
export INSTALL_SUCCESS_FILE="/$vol_name/esHome/ES.install.suc"

if [ -e $INSTALL_SUCCESS_FILE ]
then
  echo "Starting Elasticsearch server..."
  /$vol_name/esHome/startElasticsearch.sh
  sleep 30
else
  echo "Installing Elasticsearch server..."

  # Update install.properties file with required values
  sed -i "s|ORACLE_HOME=.*|ORACLE_HOME=$ORACLE_HOME|" $ES_CONFIG_FILE
  sed -i "s|ADMIN_SERVER_HOST_NAME=.*|ADMIN_SERVER_HOST_NAME=$ADMIN_SERVER_CONTAINER_NAME|" $ES_CONFIG_FILE
  sed -i "s|WLS_ADMIN_USER=.*|WLS_ADMIN_USER=$ADMIN_USERNAME|" $ES_CONFIG_FILE
  sed -i "s|ADMIN_SERVER_PORT=.*|ADMIN_SERVER_PORT=$ADMIN_PORT|" $ES_CONFIG_FILE
  sed -i "s|SEARCH_APP_USER=.*|SEARCH_APP_USER=$SEARCH_APP_USERNAME|" $ES_CONFIG_FILE
  sed -i "s|WCP_FMW_CONFIG_LOCATION=.*|WCP_FMW_CONFIG_LOCATION=$FMW_CONFIG_HOME|" $ES_CONFIG_FILE
  sed -i "s|ELASTIC_SEARCH_CLUSTER_NAME=.*|ELASTIC_SEARCH_CLUSTER_NAME=$ES_CLUSTER_NAME|" $ES_CONFIG_FILE

  # env variable to support kubernetes deployment
  if [ ! -z ${NODE_NAME} ]
  then
    sed -i "s|ELASTIC_SEARCH_NODE_NAME=.*|ELASTIC_SEARCH_NODE_NAME=$NODE_NAME|" $ES_CONFIG_FILE
    sed -i "s|ELASTIC_SEARCH_TRANSPORT_HOST=.*|ELASTIC_SEARCH_TRANSPORT_HOST=0.0.0.0|" $ES_CONFIG_FILE
    sed -i "s|ELASTIC_SEARCH_CLUSTER_HOST_LIST=.*|ELASTIC_SEARCH_CLUSTER_HOST_LIST=${UNICAST_HOST_LIST}|" $ES_CONFIG_FILE
  fi

  # create search application user
  $ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning "$ORACLE_HOME/container-scripts/createSearchApplicationUser.py"

  # install elasticsearch server
  $ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning "$ES_INSTALL_FILE" "$ES_CONFIG_FILE" "$ADMIN_PASSWORD" "$SEARCH_APP_USER_PASSWORD"

  # create search connection, if configured
  if [ "$CONFIGURE_ES_CONNECTION" == "true" ]
  then
    $ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning "$ORACLE_HOME/container-scripts/createSearchConnection.py" $HOST_NAME
    echo ""
    echo "=========================================================================================================="
    echo "IMPORTANT: Please restart the WebCenter Portal container for the search connection changes to take effect."
    echo "=========================================================================================================="
    echo ""
  fi

  # create install success file
  touch $INSTALL_SUCCESS_FILE
fi

echo ""
echo ""
if [ "$KEEP_CONTAINER_ALIVE" == "true" ]
then
  # This keeps the container running and alive
  sh /$vol_name/oracle/container-scripts/keepContainerAlive.sh $CONTAINERCONFIG_LOG_DIR $HOST_NAME $SERVER_NAME
fi
