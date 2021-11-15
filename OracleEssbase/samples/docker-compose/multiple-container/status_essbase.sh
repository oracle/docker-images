#!/bin/bash
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

DIR=`cd -P $(dirname $0);pwd`

STACK_INSTANCE_NAME=${STACK_INSTANCE_NAME:-sample}
STACK_INSTANCE_NAME=${STACK_INSTANCE_NAME,,}

docker-compose --project-name ${STACK_INSTANCE_NAME} ps -a
