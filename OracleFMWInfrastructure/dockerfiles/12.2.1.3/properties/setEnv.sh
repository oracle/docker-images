#!/bin/bash
#
#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.


export DOMAIN_NAME="infra_domain" 
export ADMIN_LISTEN_PORT="7001" 
export ADMIN_NAME="myadmin" 
export ADMIN_HOST="InfraAdminContainer" 
export ADMINISTRATION_PORT_ENABLED="true" 
export ADMINISTRATION_PORT="9002" 
export MANAGEDSERVER_PORT="8001" 
export MANAGED_NAME="infraServer1"
export RCUPREFIX="INFRA15" 
export PRODUCTION_MODE="dev" 

ENV_ARG=""
export ENV_ARG=" -e DOMAIN_NAME=$DOMAIN_NAME -e ADMIN_NAME=$ADMIN_NAME -e ADMIN_HOST=$ADMIN_HOST -e ADMIN_LISTEN_PORT=$ADMIN_LISTEN_PORT -e ADMINISTRATION_PORT_ENABLED=$ADMINISTRATION_PORT_ENABLED -e ADMINISTRATION_PORT=$ADMINISTRATION_PORT -e MANAGEDSERVER_PORT=$MANAGEDSERVER_PORT -e MANAGED_NAME=$MANAGED_NAME -e RCUPREFIX=$RCUPREFIX -e PRODUCTION_MODE=$PRODUCTION_MODE"" 
