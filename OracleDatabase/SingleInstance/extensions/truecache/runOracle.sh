#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 2024 Oracle and/or its affiliates. All rights reserved.
#
# Since: Apr, 2024
# Author:ishaan.desai@oracle.com
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

ensure_true_cache_wallet_root_bridge() {
 if [[ "${TRUE_CACHE:-}" != "true" ]]; then
  return 0
 fi

 local dbconfig_dir sid_wallet_dir target_unique_name wallet_root_dir wallet_root_link current_target

 dbconfig_dir="${ORACLE_BASE}/oradata/dbconfig/${ORACLE_SID}"
 sid_wallet_dir="${dbconfig_dir}/tde"
 target_unique_name="${TRUEDB_UNIQUE_NAME:-${ORACLE_SID}}"
 wallet_root_dir="${ORACLE_BASE}/admin/${target_unique_name}/wallet_root"
 wallet_root_link="${wallet_root_dir}/tde"

 if [[ -z "${TRUE_CACHE_BLOB:-}" || ! -f "${TRUE_CACHE_BLOB}" || -z "${TDE_WALLET_PWD:-}" ]]; then
  return 0
 fi

 if [[ -L "${sid_wallet_dir}" ]]; then
  current_target=$(readlink "${sid_wallet_dir}" || true)
  if [[ "${current_target}" == "${dbconfig_dir}/.wallet" ]]; then
   rm -f "${sid_wallet_dir}"
  fi
 fi

 mkdir -p "${sid_wallet_dir}"
 tar -xzf "${TRUE_CACHE_BLOB}" -C "${sid_wallet_dir}" ewallet.p12

 "${ORACLE_HOME}/bin/orapki" wallet create -wallet "${sid_wallet_dir}" -auto_login >/dev/null <<EOF
${TDE_WALLET_PWD}
${TDE_WALLET_PWD}
EOF

 mkdir -p "${wallet_root_dir}"

 if [[ -L "${wallet_root_link}" ]]; then
  current_target=$(readlink "${wallet_root_link}" || true)
  if [[ "${current_target}" == "${sid_wallet_dir}" ]]; then
   return 0
  fi
  rm -f "${wallet_root_link}"
 elif [[ -e "${wallet_root_link}" ]]; then
  rm -rf "${wallet_root_link}"
 fi

 ln -s "${sid_wallet_dir}" "${wallet_root_link}"
}

true_cache_storage_dir_name() {
 if [[ "${TRUE_CACHE:-}" == "true" && -n "${TRUEDB_UNIQUE_NAME:-}" ]]; then
  printf '%s\n' "${TRUEDB_UNIQUE_NAME^^}"
  return 0
 fi

 printf '%s\n' "${ORACLE_SID}"
}

prepare_true_cache_storage_alias() {
 if [[ "${TRUE_CACHE:-}" != "true" ]]; then
  return 0
 fi

 local target_dir_name checkpoint_file sid_dir target_dir current_target
 target_dir_name="$(true_cache_storage_dir_name)"
 if [[ "${target_dir_name}" == "${ORACLE_SID}" ]]; then
  return 0
 fi

 checkpoint_file="${ORACLE_BASE}/oradata/.${ORACLE_SID}${CHECKPOINT_FILE_EXTN}"
 sid_dir="${ORACLE_BASE}/oradata/${ORACLE_SID}"
 target_dir="${ORACLE_BASE}/oradata/${target_dir_name}"

 if [[ -f "${checkpoint_file}" ]]; then
  if [[ ! -d "${target_dir}" ]]; then
   return 0
  fi

  if [[ -L "${sid_dir}" ]]; then
   current_target=$(readlink "${sid_dir}" || true)
   if [[ "${current_target}" == "${target_dir}" ]]; then
    return 0
   fi
   rm -f "${sid_dir}"
  elif [[ -e "${sid_dir}" ]]; then
   return 0
  fi

  ln -s "${target_dir}" "${sid_dir}"
  return 0
 fi

 if [[ -L "${sid_dir}" ]]; then
  current_target=$(readlink "${sid_dir}" || true)
  if [[ "${current_target}" == "${target_dir}" ]]; then
   rm -f "${sid_dir}"
  fi
 fi

 if [[ -d "${target_dir}" ]]; then
  rm -rf "${target_dir}"
 fi
}

if [[ "${TRUE_CACHE}" == "true" ]]; then
 prepare_true_cache_storage_alias
 if [[ -f "${ORACLE_BASE}/oradata/.${ORACLE_SID}${CHECKPOINT_FILE_EXTN}" ]]; then
  ensure_true_cache_wallet_root_bridge
 fi
 setup_output=$("$ORACLE_BASE"/"$SETUPTC")
 if [[ -n "${setup_output}" ]]; then
  export TRUE_CACHE_BLOB="${setup_output}"
 fi
fi
