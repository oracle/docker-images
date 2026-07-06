#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2024 Oracle and/or its affiliates. All rights reserved.
#
# Since: August, 2022
# Author: abhishek.by.kumar@oracle.com/paramdeep.saini@oracle.com
# Description: Configure TCPS for the database
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# Exit immediately if a command exits with non-zero exit code
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TNS_ALIAS_HELPER="${TNS_ALIAS_HELPER:-${SCRIPT_DIR}/manageTnsAliases.sh}"
TNS_STRICT_DEDUPE_BEFORE_UPSERT="${TNS_STRICT_DEDUPE_BEFORE_UPSERT:-true}"

############# Generic helper functions for idempotent updates #################################
# Append a line to a file only when it is not already present.
# Keep repeated TCPS configuration runs from creating duplicate entries.
function ensure_line_in_file() {
    local file="$1"
    local line="$2"

    touch "$file"
    if ! grep -Fqx "$line" "$file"; then
        echo "$line" >> "$file"
    fi
}

# Remove one exact line from a target file if it exists.
# Return non-zero when the file content was already in the desired state.
function remove_exact_line_from_file() {
    local listener_file="$1"
    local target_line="$2"
    local tmp_file

    touch "$listener_file"
    tmp_file="$(mktemp)"
    awk -v target="$target_line" '
        $0 != target { print }
    ' "$listener_file" > "$tmp_file"

    if cmp -s "$listener_file" "$tmp_file"; then
        rm -f "$tmp_file"
        return 1
    fi

    mv "$tmp_file" "$listener_file"
    return 0
}

# Remove every line that matches the supplied awk regex pattern.
# Use a temp file so callers can detect whether the file actually changed.
function remove_lines_matching_regex_from_file() {
    local file="$1"
    local regex="$2"
    local tmp_file

    touch "$file"
    tmp_file="$(mktemp)"
    awk -v pattern="$regex" '
        $0 !~ pattern { print }
    ' "$file" > "$tmp_file"

    if cmp -s "$file" "$tmp_file"; then
        rm -f "$tmp_file"
        return 1
    fi

    mv "$tmp_file" "$file"
    return 0
}

# Replace a managed marker block with fresh generated content.
# Keep idempotent config updates isolated from user-managed file sections.
function upsert_managed_block() {
    local file="$1"
    local begin_marker="$2"
    local end_marker="$3"
    local content="$4"
    local tmp_file

    touch "$file"
    tmp_file="$(mktemp)"
    awk -v begin="$begin_marker" -v end="$end_marker" '
        $0 == begin {skip=1; next}
        $0 == end {skip=0; next}
        !skip {print}
    ' "$file" > "$tmp_file"

    if [ -s "$tmp_file" ]; then
        echo "" >> "$tmp_file"
    fi

    {
        echo "$begin_marker"
        printf "%s\n" "$content"
        echo "$end_marker"
    } >> "$tmp_file"

    if cmp -s "$file" "$tmp_file"; then
        rm -f "$tmp_file"
        return 1
    fi

    mv "$tmp_file" "$file"
    return 0
}

# Remove a managed marker block from a file when present.
# Return non-zero when no managed block was found to delete.
function remove_managed_block() {
    local file="$1"
    local begin_marker="$2"
    local end_marker="$3"
    local tmp_file

    touch "$file"
    tmp_file="$(mktemp)"
    awk -v begin="$begin_marker" -v end="$end_marker" '
        $0 == begin {skip=1; next}
        $0 == end {skip=0; next}
        !skip {print}
    ' "$file" > "$tmp_file"

    if cmp -s "$file" "$tmp_file"; then
        rm -f "$tmp_file"
        return 1
    fi

    mv "$tmp_file" "$file"
    return 0
}

# Render the managed sqlnet.ora fragment used for TCPS enablement.
# Keep the emitted block centralized so updates stay consistent.
function render_tcps_sqlnet_block() {
    cat <<EOF
WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = $WALLET_LOC)))
SSL_CLIENT_AUTHENTICATION = FALSE
EOF
}

# Render the listener metadata fragment needed for TCPS.
# Reuse the same wallet and SSL settings on each refresh.
function render_tcps_listener_metadata_block() {
    cat <<EOF
WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = $WALLET_LOC)))
SSL_CLIENT_AUTHENTICATION = FALSE
EOF
}

# Insert or refresh the managed TCPS listener address block.
# Preserve existing TCP listener entries while adding the TCPS address.
function upsert_tcps_listener_address_block() {
    local listener_file="$1"
    local port="$2"
    local begin_marker="# BEGIN AUTO_TCPS_LISTENER_ADDRESS_${ORACLE_SID}"
    local end_marker="# END AUTO_TCPS_LISTENER_ADDRESS_${ORACLE_SID}"
    local listener_addr="    (ADDRESS = (PROTOCOL = TCPS)(HOST = 0.0.0.0)(PORT = ${port}))"
    local tmp_file

    touch "$listener_file"
    tmp_file="$(mktemp)"
    awk -v begin="$begin_marker" -v end="$end_marker" -v addr="$listener_addr" '
        $0 == begin {skip=1; next}
        $0 == end {skip=0; next}
        !skip {
            print
            if (!inserted && $0 ~ /\(ADDRESS *= *\(PROTOCOL *= *TCP\)/) {
                print begin
                print addr
                print end
                inserted = 1
            }
        }
        END {
            if (!inserted) {
                print begin
                print addr
                print end
            }
        }
    ' "$listener_file" > "$tmp_file"

    if cmp -s "$listener_file" "$tmp_file"; then
        rm -f "$tmp_file"
        return 1
    fi

    mv "$tmp_file" "$listener_file"
    return 0
}

# Upsert a local or peer TNS alias using the helper script when available.
# Fall back to inline block generation if the helper is not executable.
function upsert_tns_alias_block() {
    local tns_file="$1"
    local alias_name="$2"
    local host="$3"
    local port="$4"
    local service_name="$5"
    local ssl_dn="$6"

    if [ -x "${TNS_ALIAS_HELPER}" ]; then
        local args=(--file "$tns_file" --alias "$alias_name" --host "$host" --port "$port" --service "$service_name" --upsert)
        if [ -n "$ssl_dn" ]; then
            args+=(--ssl-server-dn "$ssl_dn")
        fi
        if [ "${TNS_STRICT_DEDUPE_BEFORE_UPSERT,,}" = "true" ]; then
            args+=(--strict-dedupe)
        fi
        "${TNS_ALIAS_HELPER}" "${args[@]}"
        return
    fi

    echo "WARNING: ${TNS_ALIAS_HELPER} not found/executable. Falling back to inline tns upsert for ${alias_name}."
    local marker_alias
    local begin_marker
    local end_marker
    local tmp_file

    marker_alias="$(echo "$alias_name" | tr -c '[:alnum:]_' '_')"
    begin_marker="# BEGIN AUTO_TNS_${marker_alias}"
    end_marker="# END AUTO_TNS_${marker_alias}"

    touch "$tns_file"
    tmp_file="$(mktemp)"
    awk -v begin="$begin_marker" -v end="$end_marker" '
        $0 == begin {skip=1; next}
        $0 == end {skip=0; next}
        !skip {print}
    ' "$tns_file" > "$tmp_file"
    mv "$tmp_file" "$tns_file"

    if [ -s "$tns_file" ]; then
        echo "" >> "$tns_file"
    fi

    {
        echo "$begin_marker"
        echo "${alias_name}="
        echo "(DESCRIPTION="
        echo "  (ADDRESS="
        echo "    (PROTOCOL=TCPS)"
        echo "    (HOST=${host})"
        echo "    (PORT=${port})"
        echo "  )"
        echo "  (CONNECT_DATA="
        echo "    (SERVER=dedicated)"
        echo "    (SERVICE_NAME=${service_name})"
        echo "  )"
        if [ -n "$ssl_dn" ]; then
            echo "  (SECURITY="
            echo "    (SSL_SERVER_DN_MATCH=YES)"
            echo "    (SSL_SERVER_CERT_DN=${ssl_dn})"
            echo "  )"
        fi
        echo ")"
        echo "$end_marker"
    } >> "$tns_file"
}

# Validate optional DG peer inputs before peer aliases are written.
# Normalize the enable flag and apply the default peer TCPS port.
function validate_peer_env() {
    DG_PEER_ENABLED="${DG_PEER_ENABLED,,}"
    if [ "${DG_PEER_ENABLED}" != "true" ]; then
        DG_PEER_ENABLED=false
        return
    fi

    DG_PEER_PORT="${DG_PEER_PORT:-2484}"
    if [ -z "${DG_PEER_ALIAS}" ] || [ -z "${DG_PEER_HOST}" ] || [ -z "${DG_PEER_SERVICE}" ]; then
        echo "ERROR: DG_PEER_ENABLED=true requires DG_PEER_ALIAS, DG_PEER_HOST and DG_PEER_SERVICE."
        exit 1
    fi
}

function add_trusted_cert_if_missing() {
  local wallet_loc="$1"
  local cert_file="$2"
  local wallet_pwd="$3"
  local out_file
  out_file="$(mktemp)"

  if orapki wallet add -wallet "${wallet_loc}" -trusted_cert -cert "${cert_file}" \
    >"${out_file}" 2>&1 <<EOF
${wallet_pwd}
EOF
  then
    rm -f "${out_file}"
    return 0
  fi

  if grep -q "PKI-04003" "${out_file}"; then
    rm -f "${out_file}"
    return 0
  fi

  cat "${out_file}" >&2
  rm -f "${out_file}"
  return 1
}

# Split a PEM bundle into individual cert files and import each one.
# Skip cleanly when no trusted CA bundle was provided.
function import_trusted_certs_from_bundle() {
    local wallet_loc="$1"
    local bundle_file="$2"
    local wallet_pwd="$3"
    local temp_dir="$4"

    if [ -z "${bundle_file}" ] || [ ! -s "${bundle_file}" ]; then
        return 0
    fi

    rm -rf "${temp_dir}"
    mkdir -p "${temp_dir}"

    awk -v outdir="${temp_dir}" '
        /-----BEGIN CERTIFICATE-----/ {
            cert_index++
            cert_path=sprintf("%s/cert-%03d.pem", outdir, cert_index)
        }
        cert_path != "" {
            print >> cert_path
        }
        /-----END CERTIFICATE-----/ {
            close(cert_path)
            cert_path=""
        }
    ' "${bundle_file}"

    shopt -s nullglob
    for cert_file in "${temp_dir}"/*.pem; do
        [ -s "${cert_file}" ] || continue
     add_trusted_cert_if_missing "${wallet_loc}" "${cert_file}" "${wallet_pwd}"
    done
    shopt -u nullglob
}

# Resolve a TCPS secret file using preferred and fallback paths.
# Return success only when a non-empty file can be found.
function resolve_tcps_secret_file() {
    local preferred_path="$1"
    local fallback_path="$2"

    if [ -n "${preferred_path}" ] && [ -s "${preferred_path}" ]; then
        echo "${preferred_path}"
        return 0
    fi
    if [ -n "${fallback_path}" ] && [ -s "${fallback_path}" ]; then
        echo "${fallback_path}"
        return 0
    fi
    return 1
}

############# Function for setting up the Data Guard client wallet symlink ####################
function setup_dg_client_wallet_symlink() {
    echo -e "\n\nSetting up Data Guard client wallet symlink in ${DG_CLIENT_WALLET_LOC}...\n"

    # Make sure the base Data Guard wallet directory exists.
    mkdir -p "${DG_WALLET_BASE}"

    # If the symlink already points to the current database wallet, keep it.
    if [ -L "${DG_CLIENT_WALLET_LOC}" ] && [ "$(readlink "${DG_CLIENT_WALLET_LOC}")" = "${WALLET_LOC}" ]; then
        return 0
    fi

    # If a stale symlink, file, or directory exists at this path, replace it safely.
    if [ -L "${DG_CLIENT_WALLET_LOC}" ] || [ -e "${DG_CLIENT_WALLET_LOC}" ]; then
        rm -rf "${DG_CLIENT_WALLET_LOC}"
    fi

    # Create: /opt/oracle/dg-wallet/sidb-standby-dg-client-wallet -> ${WALLET_LOC}
    ln -s "${WALLET_LOC}" "${DG_CLIENT_WALLET_LOC}"
}

############# Function for setting up the client wallet ######################################
function setupClientWallet() {
    echo -e "\n\nSetting up Client Wallet in location ${CLIENT_WALLET_LOC}...\n"

    if [ ! -d "${CLIENT_WALLET_LOC}" ]; then
        mkdir -p "${CLIENT_WALLET_LOC}"
    else
        # Clean-up the client wallet directory
        rm -f "${CLIENT_WALLET_LOC}"/*
    fi

    # Create the client wallet
    orapki wallet create -wallet "${CLIENT_WALLET_LOC}" -auto_login <<EOF
${WALLET_PWD}
${WALLET_PWD}
EOF

    if [ "${CUSTOM_CERTS}" == false ]; then
        # Add the certificate
        orapki wallet add -wallet "${CLIENT_WALLET_LOC}" -trusted_cert -cert "/tmp/$(hostname)-certificate.crt" <<EOF
${WALLET_PWD}
EOF

        # Removing cert from /tmp location
        rm /tmp/"$(hostname)"-certificate.crt
    else
        import_trusted_certs_from_bundle "${CLIENT_WALLET_LOC}" "${CLIENT_TRUST_SOURCE}" "${WALLET_PWD}" "${CLIENT_TRUST_TEMP_DIR}"
    fi

    # Generate tnsnames.ora and sqlnet.ora for the consumption by the client
    : > "${CLIENT_WALLET_LOC}"/tnsnames.ora
    upsert_tns_alias_block "${CLIENT_WALLET_LOC}"/tnsnames.ora "${ORACLE_SID}" "${HOSTNAME}" "${TCPS_PORT}" "${ORACLE_SID}" ""
    upsert_tns_alias_block "${CLIENT_WALLET_LOC}"/tnsnames.ora "${ORACLE_PDB}" "${HOSTNAME}" "${TCPS_PORT}" "${ORACLE_PDB}" ""
    if [ "${DG_PEER_ENABLED}" = "true" ]; then
        upsert_tns_alias_block "${CLIENT_WALLET_LOC}"/tnsnames.ora "${DG_PEER_ALIAS}" "${DG_PEER_HOST}" "${DG_PEER_PORT}" "${DG_PEER_SERVICE}" "${DG_PEER_SSL_SERVER_DN}"
    fi

    echo "WALLET_LOCATION =
(SOURCE =
  (METHOD = FILE)
  (METHOD_DATA =
    (DIRECTORY = ./)
  )
)

SQLNET.AUTHENTICATION_SERVICES = (TCPS)
SSL_CLIENT_AUTHENTICATION = FALSE" > "${CLIENT_WALLET_LOC}"/sqlnet.ora
}

########### Configure Oracle Net Service for TCPS (sqlnet.ora and listener.ora) ##############
function configure_netservices() {
   # Add wallet location and SSL_CLIENT_AUTHENTICATION to sqlnet.ora and listener.ora
   echo -e "\n\nConfiguring Oracle Net service for TCPS...\n"

   local sqlnet_file="$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/sqlnet.ora
   local listener_file="$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/listener.ora
   local wallet_location_line="WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = $WALLET_LOC)))"
   local ssl_client_auth_line="SSL_CLIENT_AUTHENTICATION = FALSE"
   local sqlnet_changed=1
   local listener_changed=1

   # Migrate legacy unmarked TCPS lines to managed marker-owned blocks.
   remove_exact_line_from_file "$sqlnet_file" "$wallet_location_line" || true
   remove_exact_line_from_file "$sqlnet_file" "$ssl_client_auth_line" || true
   remove_exact_line_from_file "$listener_file" "$wallet_location_line" || true
   remove_exact_line_from_file "$listener_file" "$ssl_client_auth_line" || true
   remove_lines_matching_regex_from_file "$listener_file" "\\(PROTOCOL *= *TCPS\\)" || true

   if upsert_managed_block \
      "$sqlnet_file" \
      "# BEGIN AUTO_TCPS_SQLNET_${ORACLE_SID}" \
      "# END AUTO_TCPS_SQLNET_${ORACLE_SID}" \
      "$(render_tcps_sqlnet_block)"; then
      sqlnet_changed=0
   fi

   if upsert_managed_block \
      "$listener_file" \
      "# BEGIN AUTO_TCPS_LISTENER_META_${ORACLE_SID}" \
      "# END AUTO_TCPS_LISTENER_META_${ORACLE_SID}" \
      "$(render_tcps_listener_metadata_block)"; then
      listener_changed=0
   fi

   if upsert_tcps_listener_address_block "$listener_file" "${TCPS_PORT}"; then
      listener_changed=0
   fi

   # Preserve the historical non-TCPS behavior without duplicating these lines.
   ensure_line_in_file "$sqlnet_file" "DISABLE_OOB=ON"
   ensure_line_in_file "$sqlnet_file" "SQLNET.EXPIRE_TIME=3"

   if [ "$sqlnet_changed" -eq 0 ] || [ "$listener_changed" -eq 0 ]; then
      return 0
   fi
   return 1
}

# Function for reconfiguring the Listener; 'lsnrctl reload' does't work for reconfiguration
function reconfigure_listener() {
  lsnrctl stop
  lsnrctl start

  # To quickly register a service
  echo 'alter system register;' | sqlplus -s / as sysdba
}

# Function for disabling the tcps and restore the previous Oracle Net configuration
function disable_tcps() {
  local sqlnet_file="$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/sqlnet.ora
  local listener_file="$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/listener.ora
  local changed=1

  remove_managed_block "$sqlnet_file" "# BEGIN AUTO_TCPS_SQLNET_${ORACLE_SID}" "# END AUTO_TCPS_SQLNET_${ORACLE_SID}" && changed=0 || true
  remove_managed_block "$listener_file" "# BEGIN AUTO_TCPS_LISTENER_META_${ORACLE_SID}" "# END AUTO_TCPS_LISTENER_META_${ORACLE_SID}" && changed=0 || true
  remove_managed_block "$listener_file" "# BEGIN AUTO_TCPS_LISTENER_ADDRESS_${ORACLE_SID}" "# END AUTO_TCPS_LISTENER_ADDRESS_${ORACLE_SID}" && changed=0 || true

  # Backward-compatible cleanup for legacy unmarked TCPS lines.
  remove_exact_line_from_file "$sqlnet_file" "WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = $WALLET_LOC)))" && changed=0 || true
  remove_exact_line_from_file "$sqlnet_file" "SSL_CLIENT_AUTHENTICATION = FALSE" && changed=0 || true
  remove_exact_line_from_file "$listener_file" "WALLET_LOCATION = (SOURCE = (METHOD = FILE)(METHOD_DATA = (DIRECTORY = $WALLET_LOC)))" && changed=0 || true
  remove_exact_line_from_file "$listener_file" "SSL_CLIENT_AUTHENTICATION = FALSE" && changed=0 || true
  remove_lines_matching_regex_from_file "$listener_file" "\\(PROTOCOL *= *TCPS\\)" && changed=0 || true

  # Reconfigure the Listener
  if [ "$changed" -eq 0 ]; then
    echo -e "\nReconfiguring the Listener...\n"
    reconfigure_listener
  fi
  # Deleting the wallet Directories
  rm -rf "$WALLET_LOC" "$CLIENT_WALLET_LOC" "$DG_CLIENT_WALLET_LOC"
}

###########################################
################## MAIN ###################
###########################################

export ORACLE_SID
ORACLE_SID="$(grep "$ORACLE_HOME" /etc/oratab | cut -d: -f1)"

# Export ORACLE_PDB value
export ORACLE_PDB=${ORACLE_PDB:-ORCLPDB1}
ORACLE_PDB=${ORACLE_PDB^^}

# Oracle wallet location which stores the certificate
WALLET_LOC="${ORACLE_BASE}/oradata/dbconfig/${ORACLE_SID}/.tls-wallet"

# Random wallet Password
WALLET_PWD=$(openssl rand -hex 8)
# Random pkcs12 file Password
PKCS12_PWD=$(openssl rand -hex 8)

# Client wallet location
CLIENT_WALLET_LOC="${ORACLE_BASE}/oradata/clientWallet/${ORACLE_SID}"

# Data Guard client wallet symlink location.
# Default creates:
# /opt/oracle/dg-wallet/sidb-standby-dg-client-wallet -> /opt/oracle/oradata/dbconfig/${ORACLE_SID}/.tls-wallet
DG_WALLET_BASE="${DG_WALLET_BASE:-${ORACLE_BASE}/dg-wallet}"
DG_CLIENT_WALLET_NAME="${DG_CLIENT_WALLET_NAME:-sidb-standby-dg-client-wallet}"
DG_CLIENT_WALLET_LOC="${DG_WALLET_BASE}/${DG_CLIENT_WALLET_NAME}"
MY_WALLET_DIRECTORY="${MY_WALLET_DIRECTORY:-${DG_CLIENT_WALLET_LOC}}"

DG_PEER_ENABLED="${DG_PEER_ENABLED:-false}"
DG_PEER_PORT="${DG_PEER_PORT:-2484}"

# Backward compatible alias for parameterized cert mount path.
# If TCPS_CERTS_LOCATION is already provided, it takes precedence.
if [[ -z "${TCPS_CERTS_LOCATION}" && -n "${TCPS_TLS_SECRET_MOUNT_PATH}" ]]; then
  TCPS_CERTS_LOCATION="${TCPS_TLS_SECRET_MOUNT_PATH}"
fi

if [[ -z "${TCPS_CERTS_LOCATION}" ]]; then
  CUSTOM_CERTS=false
else
  CUSTOM_CERTS=true

  # CA cert bundle location from cert-manager style secret.
  CA_CERT_LOCATION="${TCPS_CERTS_LOCATION}"/ca.crt

  # Support both the legacy controller-projected names and the native secret key names.
  CLIENT_CERT_LOCATION="$(resolve_tcps_secret_file "${TCPS_CERTS_LOCATION}/cert.crt" "${TCPS_CERTS_LOCATION}/tls.crt")"
  CLIENT_KEY_LOCATION="$(resolve_tcps_secret_file "${TCPS_CERTS_LOCATION}/client.key" "${TCPS_CERTS_LOCATION}/tls.key")"

  # Temp files/dirs for backward-compatible trust bundle handling.
  EXTRACTED_CHAIN_LOCATION="/tmp/cert_chain_temp.crt"
  CLIENT_TRUST_TEMP_DIR="/tmp/client_trust_certs"
  SERVER_TRUST_TEMP_DIR="/tmp/server_trust_certs"

  if [[ -s "${CA_CERT_LOCATION}" ]]; then
    TRUSTED_CA_SOURCE="${CA_CERT_LOCATION}"
    CLIENT_TRUST_SOURCE="${CA_CERT_LOCATION}"
  else
    # Backward-compatible fallback: derive chain from cert.crt after the leaf cert.
    sed '{0,/-END CERTIFICATE-/d}' "${CLIENT_CERT_LOCATION}" > "${EXTRACTED_CHAIN_LOCATION}"
    if [[ -s "${EXTRACTED_CHAIN_LOCATION}" ]]; then
      TRUSTED_CA_SOURCE="${EXTRACTED_CHAIN_LOCATION}"
      CLIENT_TRUST_SOURCE="${EXTRACTED_CHAIN_LOCATION}"
    else
      # Last-resort compatibility path: trust the mounted leaf certificate directly for clients.
      TRUSTED_CA_SOURCE=""
      CLIENT_TRUST_SOURCE="${CLIENT_CERT_LOCATION}"
    fi
  fi
fi

# Disable TCPS control flow
if [ "${1^^}" == "DISABLE" ]; then
  disable_tcps
  exit 0
elif [[ "$1" =~ ^[0-9]+$ ]]; then
  # If TCPS_PORT is not set in the environment, honor the TCPS_PORT passed as the positional argument
  TCPS_PORT=${TCPS_PORT:-"$1"}
  HOSTNAME="$2"
  # Optional wallet password
  if [[ -n "$3" ]]; then
      WALLET_PWD="$3"
  fi
else
  HOSTNAME="$1"
  # Optional wallet password
  if [[ -n "$2" ]]; then
      WALLET_PWD="$2"
  fi
fi

# Default TCPS_PORT value
TCPS_PORT=${TCPS_PORT:-2484}
HOSTNAME="${HOSTNAME:-localhost}"
TCPS_NET_CHANGED=1
TCPS_WALLET_CHANGED=0

validate_peer_env

# Creating the wallet
echo -e "\n\nCreating Oracle Wallet for the database server side certificate...\n"
if [ ! -d "${WALLET_LOC}" ]; then
    mkdir -p "${WALLET_LOC}"
else
    echo -e "\nCleaning up existing wallet..."
    rm -f "${WALLET_LOC}"/*
fi

# Configure sqlnet.ora and listener.ora for TCPS (idempotent)
if configure_netservices; then
  TCPS_NET_CHANGED=0
fi

orapki wallet create -wallet "${WALLET_LOC}" -auto_login <<EOF
${WALLET_PWD}
${WALLET_PWD}
EOF

echo -e "\nOracle Wallet location: ${WALLET_LOC}\n"

# Create or refresh the Data Guard client wallet symlink.
# This keeps /opt/oracle/dg-wallet/sidb-standby-dg-client-wallet pointing to the server wallet location.
setup_dg_client_wallet_symlink

if [ "${CUSTOM_CERTS}" == false ]; then
    # Create a self-signed certificate using orapki utility; VALIDITY: 365 days
    echo "Creating self-signed certs"
    orapki wallet add -wallet "${WALLET_LOC}" -dn "CN=${HOSTNAME}" -keysize 2048 -self_signed -validity 365 <<EOF
${WALLET_PWD}
EOF
else
    # creating pkcs12 file in case of custom certs
    echo "Creating pkcs12 file"
    openssl pkcs12 -export -in "${CLIENT_CERT_LOCATION}" -inkey "${CLIENT_KEY_LOCATION}" -out /tmp/"$(hostname)"-open.p12 -password pass:"${PKCS12_PWD}"

    # Adding custom pkcs12 file in database server wallet
    echo "Importing pkcs12 file in server wallet"
    orapki wallet import_pkcs12 -wallet "${WALLET_LOC}" -pkcs12file /tmp/"$(hostname)"-open.p12 <<EOF
${WALLET_PWD}
${PKCS12_PWD}
EOF

    # Removing pkcs12 file from /tmp location
    rm /tmp/"$(hostname)"-open.p12

    # Import the explicit or derived CA chain into the server wallet when available.
    import_trusted_certs_from_bundle "${WALLET_LOC}" "${TRUSTED_CA_SOURCE}" "${WALLET_PWD}" "${SERVER_TRUST_TEMP_DIR}"
fi
TCPS_WALLET_CHANGED=1

# Update DB-side tnsnames.ora for local and optional peer aliases.
DB_TNS_FILE="$ORACLE_BASE"/oradata/dbconfig/"$ORACLE_SID"/tnsnames.ora
upsert_tns_alias_block "${DB_TNS_FILE}" "${ORACLE_SID}" "${HOSTNAME}" "${TCPS_PORT}" "${ORACLE_SID}" ""
upsert_tns_alias_block "${DB_TNS_FILE}" "${ORACLE_PDB}" "${HOSTNAME}" "${TCPS_PORT}" "${ORACLE_PDB}" ""
if [ "${DG_PEER_ENABLED}" = "true" ]; then
    upsert_tns_alias_block "${DB_TNS_FILE}" "${DG_PEER_ALIAS}" "${DG_PEER_HOST}" "${DG_PEER_PORT}" "${DG_PEER_SERVICE}" "${DG_PEER_SSL_SERVER_DN}"
fi

# Reconfigure listener when network config or wallet material changed.
if [ "${TCPS_NET_CHANGED}" -eq 0 ] || [ "${TCPS_WALLET_CHANGED}" -eq 1 ]; then
  reconfigure_listener
fi

if [ "${CUSTOM_CERTS}" == false ]; then
    # Export the cert to be updated in the client wallet
    orapki wallet export -wallet "${WALLET_LOC}" -dn "CN=${HOSTNAME}" -cert /tmp/"$(hostname)"-certificate.crt <<EOF
${WALLET_PWD}
EOF
fi

# Update the client wallet
setupClientWallet

if [ "${CUSTOM_CERTS}" = true ]; then
    rm -rf "${CLIENT_TRUST_TEMP_DIR}" "${SERVER_TRUST_TEMP_DIR}"
    rm -f "${EXTRACTED_CHAIN_LOCATION}"
fi
