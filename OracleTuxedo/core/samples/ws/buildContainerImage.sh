#!/bin/sh

# Copyright (c) 2022 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

docker build -t oracle/tuxedows .

echo "To run the sample, use:"
echo "docker run -d -h tuxhost --name tuxedows -v \${Local_volumes_dir}:/u01/oracle/user_projects oracle/tuxedows"
