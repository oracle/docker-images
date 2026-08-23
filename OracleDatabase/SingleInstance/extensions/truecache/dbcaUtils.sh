#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2024 Oracle and/or its affiliates. All rights reserved.
#
# Shared DBCA helpers for True Cache scripts. Oracle home layouts and DBCA
# option names vary across image and host versions, so resolve both at runtime.

resolve_dbca_path() {
  local candidate

  if [ -n "${ORACLE_HOME:-}" ] && [ -x "${ORACLE_HOME}/bin/dbca" ]; then
    echo "${ORACLE_HOME}/bin/dbca"
    return 0
  fi

  candidate="$(command -v dbca 2>/dev/null)"
  if [ -x "${candidate}" ]; then
    echo "${candidate}"
    return 0
  fi

  if [ -r /etc/oratab ]; then
    while IFS=: read -r _ home _; do
      [ -z "${home}" ] && continue
      [ "${home#\#}" != "${home}" ] && continue
      candidate="${home}/bin/dbca"
      if [ -x "${candidate}" ]; then
        echo "${candidate}"
        return 0
      fi
    done < /etc/oratab
  fi

  for candidate in /opt/oracle/product/*/*/bin/dbca /u01/app/oracle/product/*/*/bin/dbca; do
    if [ -x "${candidate}" ]; then
      echo "${candidate}"
      return 0
    fi
  done

  return 1
}

resolve_dbca_truecache_option() {
  local dbca_path=$1
  local help_output=$2
  local option_type=$3

  if [ -z "${dbca_path}" ] || [ ! -x "${dbca_path}" ]; then
    echo "resolve_dbca_truecache_option requires an executable dbca path" >&2
    return 1
  fi

  if [ -z "${help_output}" ]; then
    help_output="$("${dbca_path}" -configureDatabase -help 2>&1)"
  fi

  case "${option_type}" in
    service)
      if echo "${help_output}" | grep -q -- '-configureTrueCacheService'; then
        echo "-configureTrueCacheService"
        return 0
      fi
      if echo "${help_output}" | grep -q -- '-configureTrueCacheInstanceService'; then
        echo "-configureTrueCacheInstanceService"
        return 0
      fi
      ;;
    blob)
      if echo "${help_output}" | grep -q -- '-prepareTrueCacheConfigFile'; then
        echo "-prepareTrueCacheConfigFile"
        return 0
      fi
      if echo "${help_output}" | grep -q -- '-prepareTrueCacheInstanceBlob'; then
        echo "-prepareTrueCacheInstanceBlob"
        return 0
      fi
      ;;
  esac

  return 1
}
