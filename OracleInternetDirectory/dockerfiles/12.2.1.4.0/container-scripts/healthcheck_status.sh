#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: Pratyush Dash
#
export ORCL_ADMIN_PASSWORD=$ORCL_ADMIN_PASSWORD
export LDAP_PORT=$LDAP_PORT
server_up=$($ORACLE_HOME/bin/ldapbind -h localhost -D cn=orcladmin -w $ORCL_ADMIN_PASSWORD -p $LDAP_PORT | grep -e 'bind successful' | wc -l || echo 0)
if [ "$server_up" = "1" ]; then
   echo "OID server is up and running."
   exit 0
else
   echo "OID server is not running."
   exit 1
fi
