#!/bin/sh
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

set -e
mount_path=$1

echo Updating mount path ${mount_path}
find ${mount_path} -not -name .snapshot -exec chown 1000:1000 {} \;
chmod 0750 ${mount_path}