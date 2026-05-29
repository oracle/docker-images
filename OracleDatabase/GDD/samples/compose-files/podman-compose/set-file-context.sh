#!/bin/bash

files=(
        "${PODMANVOLLOC}/dbfiles/CATALOG"
        "/opt/containers/shard_host_file"
        "${PODMANVOLLOC}/dbfiles/ORCL1CDB"
        "${PODMANVOLLOC}/dbfiles/ORCL2CDB"
        "${PODMANVOLLOC}/dbfiles/GSMDATA"
        "${PODMANVOLLOC}/dbfiles/GSM2DATA"
        "${PODMANVOLLOC}/dbfiles/ORCL3CDB"
        "${PODMANVOLLOC}/dbfiles/ORCL4CDB"
    )

    # Check if SELinux is enabled (enforcing or permissive)
    if grep -q '^SELINUX=enforcing' /etc/selinux/config || grep -q '^SELINUX=permissive' /etc/selinux/config; then
        for file in "${files[@]}"; do
            semanage fcontext -a -t container_file_t "$file"
            restorecon -v "$file"
        done
        echo "SELinux is enabled. Updated file contexts."
    fi
