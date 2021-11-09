#!/bin/bash
#
# Copyright (c) 2020, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#
# Author: jagmohan.s.bisht@oracle.com
#

# Script to handle ext jars for SOA

  if [ ! -d "$DOMAIN_HOME/soa/oracle.soa.ext_11.1.1" ]; then

     echo "$DOMAIN_HOME/soa/oracle.soa.ext_11.1.1 does not exist... creating it now..."

     mkdir -p $DOMAIN_HOME/soa/oracle.soa.ext_11.1.1

  else

     echo "$DOMAIN_HOME/soa/oracle.soa.ext_11.1.1 exists... copying files"

     echo "source = $DOMAIN_HOME/soa/oracle.soa.ext_11.1.1/"

     echo "dest   = $ORACLE_HOME/soa/soa/modules/oracle.soa.ext_11.1.1"

     cp -r $DOMAIN_HOME/soa/oracle.soa.ext_11.1.1/* $ORACLE_HOME/soa/soa/modules/oracle.soa.ext_11.1.1/

  fi

