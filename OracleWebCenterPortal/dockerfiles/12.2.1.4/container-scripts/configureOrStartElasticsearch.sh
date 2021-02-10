#!/bin/bash
# Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
export vol_name=u01
export DOMAIN_NAME='wcp-domain'

########### SIGINT handler ############
function _int() {
   echo "Stopping container.."
   echo "SIGINT received, shutting down Elasticsearch server"
   echo ""
   /$vol_name/esHome/stopElasticsearch.sh
   exit;
}

########### SIGTERM handler ############
function _term() {
   echo "Stopping container.."
   echo "SIGTERM received, shutting down Elasticsearch server"
   echo ""
   /$vol_name/esHome/stopElasticsearch.sh
   exit;
}

########### SIGKILL handler ############
function _kill() {
   echo "Stopping container.."
   echo "SIGKILL received, shutting down Elasticsearch server"
   echo ""
   /$vol_name/esHome/stopElasticsearch.sh
   exit;
}

# Set SIGINT handler
trap _int SIGINT

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

export ES_NODE_DIR="/$vol_name/esHome/esNode"
export ES_NODEDATA_DIR="$ES_NODE_DIR/data"
export ES_NODELOG_DIR="$ES_NODE_DIR/logs"

echo ""
echo "========================================================================="
echo "                  WebCenter Portal Docker Container                      "
echo "                       Elasticsearch Server                              "
echo "                           12.2.1.4.0                                    "
echo "========================================================================="
echo ""
echo ""

# install and start elasticsearch server as oracle user
sh /$vol_name/oracle/container-scripts/installElasticsearchAndStart.sh

