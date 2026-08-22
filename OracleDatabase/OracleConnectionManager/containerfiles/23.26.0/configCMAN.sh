#!/bin/bash
# shellcheck disable=SC1090,SC2034,SC2154
#
#############################
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################
# 

source "$SCRIPT_DIR/functions.sh"

####################### Constants #################
declare -r FALSE=1
declare -r TRUE=0
declare -r CP="/bin/cp"
declare -r CMAN_ACTION_LIST="       (action_list=(aut=off)(moct=0)(mct=0)(mit=0)(conn_stats=on))"
declare -r HIDE_PASSWORD="######"
declare -A dbhost_ip_map
declare -A rule_src_map
declare -A rule_dst_map
declare -A rule_srv_map
declare -A rule_act_map
declare -A rule_next_hop_map
declare -A endpoint_host_map
declare -a dbhost_order=()
declare action=""

PROGNAME="$(basename "$0")"
export PROGNAME
###################### Constants ####################

WALLET_TMPL_STR='wallet_location =
	(source=
		(method=File)
		(method_data=
			(directory=###WALLET_LOCATION###)
		)
	)
SQLNET.WALLET_OVERRIDE = TRUE'

trim_value()
{
    local value="$1"

    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s\n' "$value"
}

strip_assignment_prefix()
{
    local value="$1"
    local prefix="$2"

    if [ -n "$prefix" ] && [[ "$value" == "${prefix}="* ]]; then
        printf '%s\n' "${value#*=}"
    elif [[ "$value" == *\?=* ]]; then
        printf '%s\n' "${value#*\?=}"
    else
        printf '%s\n' "$value"
    fi
}

extract_embedded_tnsnames()
{
    local cman_file="$1"
    local tns_file="$DB_HOME/network/admin/tnsnames.ora"
    local tmp_file

    tmp_file="$(mktemp "${logdir}/tnsnames.XXXXXX")" || error_exit "Failed to allocate temporary tnsnames.ora file"
    awk '
        /^[[:space:]]*#[[:space:]]*CMAN_TNSNAMES_BEGIN[[:space:]]*$/ { capture = 1; next }
        /^[[:space:]]*#[[:space:]]*CMAN_TNSNAMES_END[[:space:]]*$/ { capture = 0; next }
        capture { sub(/^[[:space:]]*#[[:space:]]?/, ""); print }
    ' "$cman_file" > "$tmp_file" || error_exit "Failed to extract embedded tnsnames.ora"

    if [ -s "$tmp_file" ]; then
        print_message "Copying embedded tnsnames.ora to $DB_HOME/network/admin"
        ${CP} "$tmp_file" "$tns_file" || error_exit "Failed to copy embedded tnsnames.ora to $DB_HOME/network/admin"
        chown oracle:oinstall "$tns_file" 2>/dev/null || true
    fi

    rm -f "$tmp_file"
}

is_ipv4_address()
{
    local value="$1"

    [[ "$value" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
}

is_usable_public_ip()
{
    local value="$1"

    if ! is_ipv4_address "$value"; then
        return 1
    fi

    case "$value" in
        0.0.0.0|127.*)
            return 1
            ;;
    esac

    return 0
}

container_ipv4()
{
    local ip=""

    if command -v ip >/dev/null 2>&1; then
        ip=$(ip -4 -o addr show eth0 2>/dev/null | awk 'NR == 1 { sub(/\/.*/, "", $4); print $4; exit }')
    fi

    if [ -z "$ip" ]; then
        ip=$(hostname -I 2>/dev/null | tr ' ' '\n' | awk '/^([0-9]{1,3}\.){3}[0-9]{1,3}$/ { print; exit }')
    fi

    if [ -n "$ip" ]; then
        printf '%s\n' "$ip"
        return 0
    fi

    return 1
}

resolve_host_ip()
{
    local host="$1"
    local ip=""

    if [ -z "$host" ]; then
        return 1
    fi

    ip=$(getent hosts "$host" | awk '/^([0-9]{1,3}\.){3}[0-9]{1,3}[[:space:]]/ { print $1; exit }')
    if [ -z "$ip" ]; then
        ip=$(getent hosts "$host" | awk 'NR == 1 { print $1; exit }')
    fi
    if [ -z "$ip" ] && command -v nslookup >/dev/null 2>&1; then
        ip=$(nslookup "$host" 2>/dev/null | awk '/^Address: / && $2 ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ { print $2; exit }')
    fi

    if [ -z "$ip" ]; then
        return 1
    fi

    printf '%s\n' "$ip"
}

set_public_identity_defaults()
{
    local detected_ip=""

    if [ -z "${PUBLIC_IP}" ] || ! is_usable_public_ip "${PUBLIC_IP}"; then
        PUBLIC_IP=$(resolve_host_ip "$(hostname -f 2>/dev/null)")
        if ! is_usable_public_ip "${PUBLIC_IP}"; then
            PUBLIC_IP=$(resolve_host_ip "$(hostname)")
        fi
        if ! is_usable_public_ip "${PUBLIC_IP}"; then
            detected_ip=$(container_ipv4)
            if [ -n "$detected_ip" ]; then
                PUBLIC_IP="$detected_ip"
            fi
        fi
        if [ -n "${PUBLIC_IP}" ]; then
            print_message "Container public IP set to [${PUBLIC_IP}]"
        fi
    else
        print_message "Public IP is set to ${PUBLIC_IP}"
    fi

    if [ -z "${PUBLIC_HOSTNAME}" ]; then
        PUBLIC_HOSTNAME="$(hostname)"
        print_message "RAC Node PUBLIC Hostname is not set. Setting to ${PUBLIC_HOSTNAME}"
    else
        print_message "RAC Node PUBLIC Hostname is set to ${PUBLIC_HOSTNAME}"
    fi

    if ! is_usable_public_ip "${PUBLIC_IP}"; then
        error_exit "Container public IP is not set and could not be resolved"
    fi
}

validate_level()
{
    local level_name="$1"
    local level_value="$2"

    case "$level_value" in
        user|admin|support)
            ;;
        *)
            error_exit "Invalid ${level_name} [${level_value}] specified."
            ;;
    esac
}

check_cman_env_vars()
{
    if [ -z "${DOMAIN}" ]; then
        print_message "Domain name is not defined. Setting Domain to 'example.com'"
        DOMAIN="example.com"
    else
        print_message "Domain is defined to ${DOMAIN}"
    fi

    if [ -z "${PORT}" ]; then
        print_message "PORT is not defined. Setting PORT to '1521'"
        PORT="1521"
    else
        print_message "PORT is defined to ${PORT}"
    fi

    set_public_identity_defaults

    if [ -z "${LOG_LEVEL}" ]; then
        LOG_LEVEL="user"
    fi

    if [ -z "${TRACE_LEVEL}" ]; then
        TRACE_LEVEL="user"
    fi

    validate_level "log-level" "${LOG_LEVEL}"
    validate_level "trace-level" "${TRACE_LEVEL}"

    if [ -z "${REGISTRATION_INVITED_NODES}" ]; then
        REGISTRATION_INVITED_NODES='*'
    fi

    if [ -z "${TDM}" ]; then
        TDM="no"
        TDM_THREADING_MODE=""
    else
        TDM=$(printf '%s' "${TDM}" | tr '[:upper:]' '[:lower:]')
        TDM_THREADING_MODE="dedicated"
    fi

    if [ -n "${ENABLE_REST_API}" ]; then
        ENABLE_REST_API=$(printf '%s' "${ENABLE_REST_API}" | tr '[:upper:]' '[:lower:]')
    else
        ENABLE_REST_API="false"
    fi

    if [ -z "${REST_HOST}" ]; then
        REST_HOST="$(hostname -f 2>/dev/null || hostname)"
    fi

    if [ -z "${REST_PORT}" ]; then
        REST_PORT="1525"
    fi

    if [ -z "${REST_PWD_FILE}" ]; then
        REST_PWD_FILE="/run/secrets/RESTpwdsecret"
    fi

    if [ -z "${REST_PWD_KEY}" ]; then
        REST_PWD_KEY="/run/secrets/RESTkeysecret"
    fi

    if [ "${ENABLE_REST_API}" = "true" ]; then
        print_message "REST API is Enabled"
        if [ -z "${WALLET_LOCATION}" ]; then
            WALLET_LOCATION="${DB_BASE}/wallet"
            export WALLET_LOCATION
        fi
        print_message "REST HOST is defined to ${REST_HOST}"
        print_message "REST PORT is defined to ${REST_PORT}"
        REST_PASSWORD=$(openssl pkeyutl -decrypt -in "${REST_PWD_FILE}" -inkey "${REST_PWD_KEY}") || error_exit "Failed to decrypt REST password"
    else
        print_message "REST API is disabled"
    fi
}

reset_rule_vars()
{
    RULE_SRC=""
    RULE_DST=""
    RULE_SRV=""
    RULE_ACT=""
    RULE_NEXT_HOP=""
}

check_rule_env_vars()
{
    if [ -z "${RULE_SRC}" ]; then
        RULE_SRC='*'
    fi

    if [ -z "${RULE_DST}" ]; then
        RULE_DST='*'
    fi

    if [ -z "${RULE_SRV}" ]; then
        RULE_SRV='*'
    fi

    if [ -z "${RULE_ACT}" ]; then
        RULE_ACT='accept'
    fi

    case "${RULE_ACT}" in
        accept|reject|drop)
            ;;
        *)
            error_exit "Invalid rule-action [${RULE_ACT}] specified."
            ;;
    esac
}

parse_rule_record()
{
    local db_hostvalue="$1"
    local trimmed_record
    local host=""
    local ip=""
    local token
    local key
    local value
    local last_key=""

    trimmed_record="$(trim_value "$db_hostvalue")"
    if [ -z "$trimmed_record" ]; then
        return 0
    fi

    reset_rule_vars
    IFS=':' read -r -a rule_env_vars <<< "$trimmed_record"

    for token in "${rule_env_vars[@]}"; do
        token="$(trim_value "$token")"
        if [ -z "$token" ]; then
            continue
        fi
        if [[ "$token" != *=* ]]; then
            case "$last_key" in
                RULE_NEXT_HOP|NEXT_HOP)
                    RULE_NEXT_HOP="${RULE_NEXT_HOP}:$token"
                    ;;
            esac
            continue
        fi

        key="${token%%=*}"
        value="${token#*=}"
        key="$(trim_value "$key")"
        value="$(trim_value "$value")"
        last_key="$key"

        case "$key" in
            HOST)
                host="$value"
                ;;
            IP)
                ip="$value"
                ;;
            RULE_SRC)
                RULE_SRC="$value"
                ;;
            RULE_DST)
                RULE_DST="$value"
                ;;
            RULE_SRV)
                RULE_SRV="$value"
                ;;
            RULE_ACT)
                RULE_ACT="$value"
                ;;
            RULE_NEXT_HOP|NEXT_HOP)
                RULE_NEXT_HOP="$value"
                ;;
            *)
                print_message "Ignoring unsupported DB_HOSTDETAILS token [${key}]"
                ;;
        esac
    done

    if [ -z "$host" ]; then
        error_exit "DB HOST not set. Exiting"
    fi

    check_rule_env_vars

    print_message "DB_HOST name is ${host}"
    dbhost_order+=("$host")
    dbhost_ip_map["$host"]="$ip"
    rule_src_map["$host"]="$RULE_SRC"
    rule_dst_map["$host"]="$RULE_DST"
    rule_srv_map["$host"]="$RULE_SRV"
    rule_act_map["$host"]="$RULE_ACT"
    rule_next_hop_map["$host"]="$RULE_NEXT_HOP"
}

get_dbhost_details()
{
    local db_hostdetail_values
    local db_hostvalue

    db_hostdetail_values="$(strip_assignment_prefix "${DB_HOSTDETAILS}" "DB_HOSTDETAILS")"
    IFS=',' read -r -a db_hostvalues <<< "$db_hostdetail_values"

    for db_hostvalue in "${db_hostvalues[@]}"; do
        parse_rule_record "$db_hostvalue"
    done
}

check_dbhost_connections()
{
    local host
    local resolved_ip=""

    for host in "${dbhost_order[@]}"; do
        print_message " -- : ${host} --> ${dbhost_ip_map[$host]}"

        if [ -n "${dbhost_ip_map[$host]}" ]; then
            print_message "Using explicit IP for host ${host}: ${dbhost_ip_map[$host]}"
            continue
        fi

        resolved_ip="$(resolve_host_ip "$host")"
        if [ -z "$resolved_ip" ]; then
            error_exit "IP not found for host ${host}"
        fi

        dbhost_ip_map["$host"]="$resolved_ip"
        print_message "Resolved host ip : ${host} --> ${resolved_ip}"
    done
}

map_kubernetes_endpoint_hosts()
{
    local host
    local pod_namespace
    local service_name
    local service_namespace
    local token_file="/var/run/secrets/kubernetes.io/serviceaccount/token"
    local ca_file="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
    local ns_file="/var/run/secrets/kubernetes.io/serviceaccount/namespace"
    local api_host="${KUBERNETES_SERVICE_HOST}"
    local api_port="${KUBERNETES_SERVICE_PORT:-443}"
    local token
    local endpoint_json
    local hosts_file
    local endpoint_ip
    local endpoint_name
    local endpoint_host=""
    local rule_dst
    local normalized_rule_dst
    local normalized_host

    if [ "$action" != "" ]; then
        return 0
    fi

    if [ -z "${api_host}" ] || [ ! -f "${token_file}" ] || [ ! -f "${ns_file}" ]; then
        print_message "Kubernetes service account details not available. Skipping endpoint host mapping."
        return 0
    fi

    if ! command -v curl >/dev/null 2>&1 || ! command -v python3 >/dev/null 2>&1; then
        print_message "curl or python3 not available. Skipping endpoint host mapping."
        return 0
    fi

    pod_namespace=$(cat "${ns_file}")
    token=$(cat "${token_file}")

    for host in "${dbhost_order[@]}"; do
        if [ -z "${host}" ] || is_ipv4_address "${host}"; then
            continue
        fi

        service_name=$(python3 - "$host" <<'PYEOF'
import sys
host = sys.argv[1].strip().rstrip(".")
parts = host.split(".")
print(parts[0] if parts and parts[0] else "")
PYEOF
)
        service_namespace=$(python3 - "$host" "$pod_namespace" <<'PYEOF'
import sys
host = sys.argv[1].strip().rstrip(".")
default_ns = sys.argv[2]
parts = host.split(".")
namespace = default_ns
if len(parts) >= 4 and parts[2] == "svc":
    namespace = parts[1]
elif len(parts) >= 2:
    namespace = parts[1]
print(namespace)
PYEOF
)

        if [ -z "${service_name}" ] || [ -z "${service_namespace}" ]; then
            continue
        fi

        print_message "Mapping Kubernetes endpoints for service ${service_namespace}/${service_name}"
        endpoint_json=$(curl -fsS --noproxy "*" --cacert "${ca_file}" \
            -H "Authorization: Bearer ${token}" \
            "https://${api_host}:${api_port}/api/v1/namespaces/${service_namespace}/endpoints/${service_name}" 2>/dev/null)
        if [ $? -ne 0 ] || [ -z "${endpoint_json}" ]; then
            print_message "Unable to read Kubernetes endpoints for ${service_namespace}/${service_name}. Skipping endpoint host mapping."
            continue
        fi

        hosts_file=$(mktemp)
        echo "${endpoint_json}" | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

seen = set()
for subset in data.get("subsets", []):
    for address in subset.get("addresses", []):
        ip = address.get("ip")
        name = (address.get("targetRef") or {}).get("name")
        if not ip or not name:
            continue
        key = (ip, name)
        if key in seen:
            continue
        seen.add(key)
        print(f"{ip}\t{name}")
' > "${hosts_file}"
        if [ -s "${hosts_file}" ]; then
            while read -r endpoint_ip endpoint_name; do
                if [ -z "${endpoint_ip}" ] || [ -z "${endpoint_name}" ]; then
                    continue
                fi
                printf '%s\t%s\n' "${endpoint_ip}" "${endpoint_name}" | sudo tee -a "${ETCHOSTS:-/etc/hosts}" > /dev/null
                print_message "Added Kubernetes endpoint host mapping: ${endpoint_ip} ${endpoint_name}"
                if [ -z "${endpoint_host}" ]; then
                    endpoint_host="${endpoint_name}"
                fi
            done < "${hosts_file}"
        else
            print_message "No named endpoint addresses found for ${service_namespace}/${service_name}"
        fi
        rm -f "${hosts_file}"

        if [ -n "${endpoint_host}" ]; then
            endpoint_host_map["$host"]="${endpoint_host}"
            rule_dst="${rule_dst_map[$host]}"
            normalized_rule_dst="${rule_dst%.}"
            normalized_host="${host%.}"
            case "${normalized_rule_dst}" in
                "${normalized_host}"|"${service_name}"|"${service_name}.${service_namespace}"|"${service_name}.${service_namespace}.svc"|"${service_name}.${service_namespace}.svc.cluster.local")
                    rule_dst_map["$host"]="${endpoint_host}"
                    print_message "Mapped CMAN rule destination ${rule_dst} to endpoint host ${endpoint_host}"
                    ;;
            esac
        fi
    done
}


map_kubernetes_namespace_endpoint_hosts()
{
    local pod_namespace
    local token_file="/var/run/secrets/kubernetes.io/serviceaccount/token"
    local ca_file="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
    local ns_file="/var/run/secrets/kubernetes.io/serviceaccount/namespace"
    local api_host="${KUBERNETES_SERVICE_HOST}"
    local api_port="${KUBERNETES_SERVICE_PORT:-443}"
    local token
    local endpoints_json
    local hosts_file
    local endpoint_ip
    local endpoint_name

    if [ "$action" != "" ]; then
        return 0
    fi

    if [ -z "${api_host}" ] || [ ! -f "${token_file}" ] || [ ! -f "${ns_file}" ]; then
        print_message "Kubernetes service account details not available. Skipping namespace endpoint host mapping."
        return 0
    fi

    if ! command -v curl >/dev/null 2>&1 || ! command -v python3 >/dev/null 2>&1; then
        print_message "curl or python3 not available. Skipping namespace endpoint host mapping."
        return 0
    fi

    pod_namespace=$(cat "${ns_file}")
    token=$(cat "${token_file}")

    print_message "Mapping Kubernetes endpoint hostnames in namespace ${pod_namespace}"
    endpoints_json=$(curl -fsS --noproxy "*" --cacert "${ca_file}" \
        -H "Authorization: Bearer ${token}" \
        "https://${api_host}:${api_port}/api/v1/namespaces/${pod_namespace}/endpoints" 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "${endpoints_json}" ]; then
        print_message "Unable to list Kubernetes endpoints for namespace ${pod_namespace}. Skipping namespace endpoint host mapping."
        return 0
    fi

    hosts_file=$(mktemp)
    echo "${endpoints_json}" | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

seen = set()
for item in data.get("items", []):
    for subset in item.get("subsets", []):
        for address in subset.get("addresses", []):
            ip = address.get("ip")
            target = address.get("targetRef") or {}
            name = target.get("name")
            kind = target.get("kind")
            if not ip or not name:
                continue
            if kind and kind != "Pod":
                continue
            key = (ip, name)
            if key in seen:
                continue
            seen.add(key)
            print(f"{ip}\t{name}")
' > "${hosts_file}"
    if [ -s "${hosts_file}" ]; then
        while read -r endpoint_ip endpoint_name; do
            if [ -z "${endpoint_ip}" ] || [ -z "${endpoint_name}" ]; then
                continue
            fi
            if getent hosts "${endpoint_name}" >/dev/null 2>&1; then
                continue
            fi
            printf '%s\t%s\n' "${endpoint_ip}" "${endpoint_name}" | sudo tee -a "${ETCHOSTS:-/etc/hosts}" > /dev/null
            print_message "Added Kubernetes endpoint host mapping: ${endpoint_ip} ${endpoint_name}"
        done < "${hosts_file}"
    else
        print_message "No named Kubernetes endpoint addresses found for namespace ${pod_namespace}"
    fi
    rm -f "${hosts_file}"
}

all_check()
{
    if [ -z "${DB_HOSTDETAILS}" ]; then
        print_message "DB_HOSTDETAILS not set. Using default catch-all rule"
        return 0
    fi

    print_message "DB_HOSTDETAILS name is ${DB_HOSTDETAILS}"
    get_dbhost_details
    check_dbhost_connections
}

####################################### ETC Host Function #############################################################

setupEtcResolvConf()
{
    if [ "$action" = "delete" ]; then
        return 0
    fi

    if [ -n "${DNS_SERVER}" ]; then
        sudo sh -c "printf '%s\n' 'search ${DOMAIN}' > /etc/resolv.conf"
        sudo sh -c "printf '%s\n' 'nameserver ${DNS_SERVER}' >> /etc/resolv.conf"
    fi
}

SetupEtcHosts()
{
    local tmp_hosts

    if [ "$action" = "delete" ]; then
        return 0
    fi

    if [ -n "${HOSTFILE}" ]; then
        if [ ! -f "${HOSTFILE}" ]; then
            error_exit "Host file [${HOSTFILE}] does not exist"
        fi
        sudo sh -c "cat \"${HOSTFILE}\" > /etc/hosts"
        return 0
    fi

    tmp_hosts="$(mktemp "${logdir}/hosts.XXXXXX")" || error_exit "Failed to allocate temporary hosts file"
    if [ -f /etc/hosts ]; then
        cp /etc/hosts "$tmp_hosts"
    fi

    awk -v host="${PUBLIC_HOSTNAME}" -v fqdn="${PUBLIC_HOSTNAME}.${DOMAIN}" '
        index($0, host) == 0 && index($0, fqdn) == 0 { print }
    ' "$tmp_hosts" > "${tmp_hosts}.filtered"

    if ! grep -q '^127\.0\.0\.1[[:space:]]' "${tmp_hosts}.filtered"; then
        printf '127.0.0.1\tlocalhost.localdomain\tlocalhost\n' >> "${tmp_hosts}.filtered"
    fi
    printf '%s\t%s.%s\t%s\n' "${PUBLIC_IP}" "${PUBLIC_HOSTNAME}" "${DOMAIN}" "${PUBLIC_HOSTNAME}" >> "${tmp_hosts}.filtered"

    sudo sh -c "cat \"${tmp_hosts}.filtered\" > /etc/hosts"
    rm -f "$tmp_hosts" "${tmp_hosts}.filtered"
}

####################################### cman.ora generation ###########################################################

replace_rule_list()
{
    local cman_file_path="$1"
    local rules_file="$2"
    local tmp_file

    tmp_file="$(mktemp "${logdir}/cman.rulelist.XXXXXX")" || error_exit "Failed to allocate temporary cman.ora file"

    awk -v replacement_file="$rules_file" '
        function paren_delta(line, opens, closes)
        {
            opens = gsub(/\(/, "(", line)
            closes = gsub(/\)/, ")", line)
            return opens - closes
        }

        {
            if (!skipping && $0 ~ /^[[:space:]]*\(rule_list=/) {
                while ((getline replacement_line < replacement_file) > 0) {
                    print replacement_line
                }
                close(replacement_file)
                skipping = 1
                depth = paren_delta($0)
                next
            }

            if (skipping) {
                depth += paren_delta($0)
                if (depth <= 0) {
                    skipping = 0
                }
                next
            }

            print
        }
    ' "$cman_file_path" > "$tmp_file" || error_exit "Failed to update rule_list in ${cman_file_path}"

    mv "$tmp_file" "$cman_file_path"
}


format_next_hop_description()
{
    local next_hop="$1"
    local host
    local port

    if [[ "$next_hop" == \(* ]]; then
        printf '    %s\n' "$next_hop"
        return 0
    fi

    host="${next_hop%:*}"
    port="${next_hop##*:}"
    if [ "$host" = "$port" ]; then
        port="1521"
    fi

    printf '    (description=(address=(protocol=tcp)(host=%s)(port=%s)))\n' "$host" "$port"
}

insert_next_hop_block()
{
    local cman_file_path="$1"
    local next_hop_file
    local tmp_file
    local host
    local next_hop
    local seen="|"
    local count=0

    next_hop_file="$(mktemp "${logdir}/cman.nexthop.XXXXXX")" || error_exit "Failed to allocate temporary CMAN next_hop file"
    {
        echo "  (next_hop="
        for host in "${dbhost_order[@]}"; do
            next_hop="${rule_next_hop_map[$host]}"
            if [ -z "$next_hop" ]; then
                continue
            fi
            case "$seen" in
                *"|$next_hop|"*)
                    continue
                    ;;
            esac
            seen="${seen}${next_hop}|"
            format_next_hop_description "$next_hop"
            count=$((count + 1))
        done
        echo "  )"
    } > "$next_hop_file"

    if [ "$count" -eq 0 ]; then
        rm -f "$next_hop_file"
        return 0
    fi

    tmp_file="$(mktemp "${logdir}/cman.nexthop.out.XXXXXX")" || error_exit "Failed to allocate temporary CMAN file"
    awk -v next_hop_file="$next_hop_file" '
        {
            print
            if (!inserted && $0 ~ /^[[:space:]]*\(address=/) {
                while ((getline line < next_hop_file) > 0) {
                    print line
                }
                close(next_hop_file)
                inserted = 1
            }
        }
    ' "$cman_file_path" > "$tmp_file" || error_exit "Failed to insert CMAN next_hop block"

    mv "$tmp_file" "$cman_file_path"
    rm -f "$next_hop_file"
}

generate_rule_list_file()
{
    local rules_file="$1"
    local host
    local dst

    {
        echo "  (rule_list="
        if [ "${#dbhost_order[@]}" -eq 0 ]; then
            echo "    (rule="
            echo "       (src=*)(dst=*)(srv=*)(act=accept)"
            echo "$CMAN_ACTION_LIST"
            echo "    )"
        else
            for host in "${dbhost_order[@]}"; do
                dst="${rule_dst_map[$host]}"
                if [ -z "${dst}" ] && [ -n "${endpoint_host_map[$host]}" ]; then
                    dst="${endpoint_host_map[$host]}"
                fi
                echo "    (rule="
                printf '       (src=%s)(dst=%s)(srv=%s)(act=%s)
' \
                    "${rule_src_map[$host]}" \
                    "$dst" \
                    "${rule_srv_map[$host]}" \
                    "${rule_act_map[$host]}"
                echo "$CMAN_ACTION_LIST"
                echo "    )"
            done
        fi
        echo "  )"
    } > "$rules_file"
}

cman_file()
{
    local generated_file
    local rules_file

    generated_file="$(mktemp "${logdir}/${CMANORA}.XXXXXX")" || error_exit "Failed to allocate temporary cman.ora file"
    cp "$SCRIPT_DIR/$CMANORA" "$generated_file" || error_exit "Failed to copy CMAN template"

    sed -i \
        -e "s|###CMAN_HOSTNAME###|${PUBLIC_HOSTNAME}|g" \
        -e "s|###DOMAIN###|${DOMAIN}|g" \
        -e "s|###DB_HOME###|${DB_HOME}|g" \
        -e "s|###PORT###|${PORT}|g" \
        -e "s|###LOG_LEVEL###|${LOG_LEVEL}|g" \
        -e "s|###TRACE_LEVEL###|${TRACE_LEVEL}|g" \
        -e "s|(registration_invited_nodes=.*)|(registration_invited_nodes=${REGISTRATION_INVITED_NODES})|g" \
        "$generated_file" || error_exit "Failed to render CMAN template"

    insert_next_hop_block "$generated_file"

    if [ "${ENABLE_REST_API}" = "true" ]; then
        sed -i \
            -e "s|###REST_HOST###|${REST_HOST}|g" \
            -e "s|###REST_PORT###|${REST_PORT}|g" \
            "$generated_file" || error_exit "Failed to configure REST address"
    else
        sed -i -e "/(REST_ADDRESS=/d" "$generated_file" || error_exit "Failed to remove REST address"
    fi

    if [ "${TDM}" = "yes" ]; then
        sed -i \
            -e "s|###TDM###|${TDM}|g" \
            -e "s|###TDM_THREADING_MODE###|${TDM_THREADING_MODE}|g" \
            "$generated_file" || error_exit "Failed to configure TDM"
    else
        sed -i \
            -e "/(TDM=/d" \
            -e "/(TDM_THREADING_MODE=/d" \
            "$generated_file" || error_exit "Failed to remove TDM settings"
    fi

    rules_file="$(mktemp "${logdir}/cman.rules.XXXXXX")" || error_exit "Failed to allocate temporary CMAN rule file"
    generate_rule_list_file "$rules_file"
    replace_rule_list "$generated_file" "$rules_file"
    rm -f "$rules_file"

    if [ -n "${WALLET_LOCATION}" ]; then
        printf '\n%s\n' "$WALLET_TMPL_STR" >> "$generated_file"
        sed -i -e "s|###WALLET_LOCATION###|${WALLET_LOCATION}|g" "$generated_file" || error_exit "Failed to set wallet location"
    fi

    mv "$generated_file" "$logdir/$CMANORA"
    chown oracle:oinstall "$logdir/$CMANORA"
}

delete_rule_block()
{
    local cman_file_path="$1"
    local rule_line="$2"
    local tmp_file
    local awk_status

    tmp_file="$(mktemp "${logdir}/cman.delete.XXXXXX")" || error_exit "Failed to allocate temporary cman.ora file"

    awk -v rule_line="$rule_line" '
        function paren_delta(line, opens, closes)
        {
            opens = gsub(/\(/, "(", line)
            closes = gsub(/\)/, ")", line)
            return opens - closes
        }

        function flush_buffer()
        {
            if (!matched) {
                printf "%s", buffer
            } else {
                deleted = 1
            }
            buffer = ""
            matched = 0
            collecting = 0
            depth = 0
        }

        {
            if (!collecting && $0 ~ /^[[:space:]]*\(rule=/) {
                collecting = 1
                depth = paren_delta($0)
                buffer = $0 ORS
                matched = (index($0, rule_line) > 0)
                if (depth <= 0) {
                    flush_buffer()
                }
                next
            }

            if (collecting) {
                depth += paren_delta($0)
                buffer = buffer $0 ORS
                if (index($0, rule_line) > 0) {
                    matched = 1
                }
                if (depth <= 0) {
                    flush_buffer()
                }
                next
            }

            print
        }

        END
        {
            if (!deleted) {
                exit 2
            }
        }
    ' "$cman_file_path" > "$tmp_file"
    awk_status=$?

    case "$awk_status" in
        0)
            mv "$tmp_file" "$cman_file_path"
            ;;
        2)
            rm -f "$tmp_file"
            error_exit "cman rule ${rule_line} not found in cman config file ${cman_file_path}. Exiting."
            ;;
        *)
            rm -f "$tmp_file"
            error_exit "Failed to delete cman rule ${rule_line}"
            ;;
    esac
}

deleterule()
{
    local cman_file_path="$DB_HOME/network/admin/$CMANORA"
    local cman_rule

    if [ ! -f "$cman_file_path" ]; then
        error_exit "cman config file ${cman_file_path} not found. Exiting."
    fi

    cman_rule="$(printf '(src=%s)(dst=%s)(srv=%s)(act=%s)' \
        "${RULE_SRC}" \
        "${RULE_DST}" \
        "${RULE_SRV}" \
        "${RULE_ACT}")"

    print_message "CMAN Rule to delete=[${cman_rule}]"
    delete_rule_block "$cman_file_path" "$cman_rule"
    reload_cman
}

copycmanora()
{
    mkdir -p "$DB_HOME/network/admin/" || error_exit "Failed to create $DB_HOME/network/admin/"
    sleep 2
    cp "$logdir/$CMANORA" "$DB_HOME/network/admin/" || error_exit "Failed to copy cman.ora to $DB_HOME/network/admin/"
    chown -R oracle:oinstall "$DB_HOME/network/admin/"
}

configure_rest_api()
{
    local oracle_home="${ORACLE_HOME:-$DB_HOME}"

    if [ "${ENABLE_REST_API}" != "true" ]; then
        return 0
    fi

    print_message "REST API enabled. Configuring REST API"

    echo "${oracle_home}/bin/orapki wallet create -wallet ${WALLET_LOCATION} -pwd ${HIDE_PASSWORD}"
    "${oracle_home}/bin/orapki" wallet create -wallet "${WALLET_LOCATION}" -pwd "${REST_PASSWORD}" || error_exit "Failed to create REST wallet"

    echo "${oracle_home}/bin/orapki wallet add -wallet ${WALLET_LOCATION} -dn \"CN=${REST_HOST},C=US\" -keysize 2048 -self_signed -validity 365 -pwd ${HIDE_PASSWORD}"
    "${oracle_home}/bin/orapki" wallet add -wallet "${WALLET_LOCATION}" -dn "CN=${REST_HOST},C=US" -keysize 2048 -self_signed -validity 365 -pwd "${REST_PASSWORD}" || error_exit "Failed to add REST wallet certificate"

    printf '%s\n' "${REST_PASSWORD}" | "${oracle_home}/bin/mkstore" -wrl "${WALLET_LOCATION}" -createEntry oracle "${REST_PASSWORD}" || error_exit "Failed to create REST wallet entry"

    echo "${oracle_home}/bin/orapki wallet create -wallet ${WALLET_LOCATION} -auto_login -pwd ${HIDE_PASSWORD}"
    "${oracle_home}/bin/orapki" wallet create -wallet "${WALLET_LOCATION}" -auto_login -pwd "${REST_PASSWORD}" || error_exit "Failed to enable REST wallet auto login"

    echo "${oracle_home}/bin/orapki wallet export -wallet ${WALLET_LOCATION} -dn \"CN=${REST_HOST},C=US\" -cert ${WALLET_LOCATION}/RESTAPI.cert"
    "${oracle_home}/bin/orapki" wallet export -wallet "${WALLET_LOCATION}" -dn "CN=${REST_HOST},C=US" -cert "${WALLET_LOCATION}/RESTAPI.cert" || error_exit "Failed to export REST API certificate"

    sleep 2
    print_message "Displaying the REST-API certificate"
    echo "${oracle_home}/bin/orapki cert display -cert ${WALLET_LOCATION}/RESTAPI.cert"
    "${oracle_home}/bin/orapki" cert display -cert "${WALLET_LOCATION}/RESTAPI.cert" || error_exit "Failed to display REST API certificate"
    print_message "================================================="
    print_message "Copy over ${WALLET_LOCATION}/RESTAPI.cert to the client host to use the REST API of the Oracle Connection Manager."
    print_message "================================================="
}

reload_cman()
{
    local output

    output=$("$DB_HOME/bin/cmctl" reload -c "CMAN_${PUBLIC_HOSTNAME}.${DOMAIN}" 2>&1)
    printf '%s\n' "$output"
    if printf '%s\n' "$output" | grep -Eq 'TNS-[0-9]+|not yet started|Unable to'; then
        error_exit "CMAN reload failed"
    fi
}

start_cman()
{
    local output

    export ORACLE_HOME="$DB_HOME"
    output=$("$DB_HOME/bin/cmctl" startup -c "CMAN_${PUBLIC_HOSTNAME}.${DOMAIN}" 2>&1)
    printf '%s\n' "$output"
    if printf '%s\n' "$output" | grep -Eq 'TNS-[0-9]+|Unable to'; then
        error_exit "CMAN startup failed"
    fi
}

stop_cman()
{
    local cmaninst="$1"

    export ORACLE_HOME="$DB_HOME"
    "$DB_HOME/bin/cmctl" shutdown -c "$cmaninst"
}

status_cman()
{
    local output

    export ORACLE_HOME="$DB_HOME"
    output=$("$DB_HOME/bin/cmctl" show service -c "CMAN_${PUBLIC_HOSTNAME}.${DOMAIN}" 2>&1)
    printf '%s\n' "$output"

    if ! printf '%s\n' "$output" | grep -Eq 'TNS-[0-9]+|not yet started|Unable to'; then
        print_message "cman [CMAN_${PUBLIC_HOSTNAME}.${DOMAIN}] started sucessfully"
    else
        if [ -z "${CMAN_DEBUG}" ]; then
            error_exit "Cman [CMAN_${PUBLIC_HOSTNAME}.${DOMAIN}] startup failed. Exiting"
        else
            print_message "Cman [CMAN_${PUBLIC_HOSTNAME}.${DOMAIN}] startup failed. Debug mode"
            tail -f "$logfile"
        fi
    fi
}

parse_delete_rule_details()
{
    local del_rule_details
    local token
    local key
    local value

    if [ -z "${RULEDETAILS}" ]; then
        error_exit "RULEDETAILS not set. Exiting"
    fi

    del_rule_details="$(strip_assignment_prefix "${RULEDETAILS}" "RULEDETAILS")"
    reset_rule_vars
    IFS=':' read -r -a del_rule_vars <<< "$del_rule_details"

    for token in "${del_rule_vars[@]}"; do
        token="$(trim_value "$token")"
        if [ -z "$token" ] || [[ "$token" != *=* ]]; then
            continue
        fi

        key="${token%%=*}"
        value="${token#*=}"
        key="$(trim_value "$key")"
        value="$(trim_value "$value")"

        case "$key" in
            RULE_SRC)
                RULE_SRC="$value"
                ;;
            RULE_DST)
                RULE_DST="$value"
                ;;
            RULE_SRV)
                RULE_SRV="$value"
                ;;
            RULE_ACT)
                RULE_ACT="$value"
                ;;
            RULE_NEXT_HOP|NEXT_HOP)
                RULE_NEXT_HOP="$value"
                ;;
        esac
    done

    check_rule_env_vars
}

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

while [ $# -gt 0 ]; do
    case "$1" in
        -addrule)
            action="add"
            ;;
        -delrule)
            action="delete"
            ;;
        -e)
            shift
            envdetail="$1"
            envname=$(echo "$envdetail" | cut -d"=" -f 1)
            envval=$(echo "$envdetail" | cut -d"=" -f 2-)
            echo "name=[${envname}]. val=[${envval}]"
            export "${envname}=${envval}"
            ;;
        *)
            error_exit "* Error: Invalid argument [$1] specified.*\n"
            ;;
    esac
    shift
done

check_cman_env_vars
setupEtcResolvConf
SetupEtcHosts

if [ "$action" = "delete" ]; then
    parse_delete_rule_details
    deleterule
    exit 0
fi

if [ -n "${USER_CMAN_FILE}" ]; then
    if [ ! -f "${USER_CMAN_FILE}" ]; then
        error_exit "User supplied cman.ora file [${USER_CMAN_FILE}] not found. Exiting CMAN-Setup."
    fi
    print_message "Using the user defined cman.ora file=[${USER_CMAN_FILE}]"
    map_kubernetes_namespace_endpoint_hosts
    ${CP} "${USER_CMAN_FILE}" "$logdir/$CMANORA"
else
    all_check
    map_kubernetes_endpoint_hosts
    print_message "Generating CMAN file"
    cman_file
fi

print_message "Copying CMAN file to $DB_HOME/network/admin"
copycmanora
extract_embedded_tnsnames "$DB_HOME/network/admin/$CMANORA"
configure_rest_api
print_message "Starting CMAN"
start_cman
print_message "Checking CMAN Status"
status_cman

print_message "################################################"
print_message " CONNECTION MANAGER IS READY TO USE!            "
print_message "################################################"
