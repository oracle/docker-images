#!/bin/sh
#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

if [ ! -e ${ARBORPATH} ]; then
   echo "ARBORPATH does not exist, creating"
   mkdir -p ${ARBORPATH}
fi

chmod 0750 ${ARBORPATH}

