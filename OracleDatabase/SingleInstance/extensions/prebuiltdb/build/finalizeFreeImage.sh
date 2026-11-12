#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2026 Oracle and/or its affiliates. All rights reserved.
#
# Since: September, 2026
# Author: mohammed.qureshi@oracle.com
# Description: Restore runtime files and complete the Free image root setup.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

set -euo pipefail

: "${ORACLE_BASE:?}"
: "${ORACLE_HOME:?}"

if [ -f /tmp/prebuilt-runtime/oratab ]; then
    cp /tmp/prebuilt-runtime/oratab /etc/oratab
    chown oracle:oinstall /etc/oratab
fi
if [ -f /tmp/prebuilt-runtime/oracle-free-26ai ]; then
    cp /tmp/prebuilt-runtime/oracle-free-26ai /etc/init.d/oracle-free-26ai
fi

"${ORACLE_BASE}/oraInventory/orainstRoot.sh"
"${ORACLE_HOME}/root.sh"

if [ -f /tmp/prebuilt-runtime/oracle-free-26ai.LICENSE ]; then
    mkdir -p /usr/share/doc/oracle-free-26ai /licenses
    cp /tmp/prebuilt-runtime/oracle-free-26ai.LICENSE /usr/share/doc/oracle-free-26ai/LICENSE
    cp /tmp/prebuilt-runtime/oracle-free-26ai.LICENSE /licenses/license.txt
    chmod 644 /usr/share/doc/oracle-free-26ai/LICENSE /licenses/license.txt
fi

rm -rf /tmp/prebuilt-runtime
