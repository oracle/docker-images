#!/bin/bash
#
# Copyright (c) 2019, 2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Description: This script is used to Create Sites Domain/start Admin Server or start Managed Server.
#


if [ -z ${WCSITES_ADMIN_HOSTNAME} ]
then
	echo ""
	echo " WCSITES_ADMIN_HOSTNAME not set $WCSITES_ADMIN_HOSTNAME, So creating domain or starting Admin Server."
	echo ""
	sh $SITES_CONTAINER_SCRIPTS/createSitesDomainandStartAdmin.sh
else
	echo ""
	echo " WCSITES_ADMIN_HOSTNAME set to $WCSITES_ADMIN_HOSTNAME, So starting Managed Server"
	echo ""
	sh $SITES_CONTAINER_SCRIPTS/startSitesServer.sh
fi
