#!/bin/sh
# Copyright (c) 2022 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
pushd ./latest
docker build -t oracle/mgmtagent-container .
popd
