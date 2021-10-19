#!/bin/bash
# Copyright (c)  2020,2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
export vol_name=u01
export server=WC_Portal

/$vol_name/oracle/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /$vol_name/oracle/container-scripts/createContentServerConnection.py
