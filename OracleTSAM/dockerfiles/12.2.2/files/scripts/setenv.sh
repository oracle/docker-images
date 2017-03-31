#!/bin/bash
if [ -z "$DOMAIN_NAME" ];then
  DOMAIN_NAME=tsamdomain
fi
export WLHOME=/u01/oracle/oraHome/tsam12.2.2.0.0/wls
export WLDOM=$WLHOME/user_projects/domains/$DOMAIN_NAME
export DEPLOY=/u01/oracle/oraHome/tsam12.2.2.0.0/deploy

if [ -n "$MY_ENV_DIR" ];then source $MY_ENV_DIR/$ENVS_FILE; fi
