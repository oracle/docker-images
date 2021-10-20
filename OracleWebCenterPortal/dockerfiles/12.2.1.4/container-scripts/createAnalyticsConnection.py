#!/usr/bin/python
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
import sys

#============================================================
#Connect To AdminServer and create Analytics Connection
#============================================================

adminHost     = os.environ.get("ADMIN_SERVER_CONTAINER_NAME")
adminPort     = os.environ.get("ADMIN_PORT")
adminName     = os.environ.get("ADMIN_USERNAME")
adminPassword = os.environ.get("ADMIN_PASSWORD")
url = adminHost + ":" + adminPort
connect(adminName, adminPassword, url)
createAnalyticsCollectorConnection(appName='webcenter', connectionName='MyAnalyticsCollector', isUnicast=1,
collectorHost='localhost', collectorPort=31314, isEnabled=1, timeout=30, default=1)