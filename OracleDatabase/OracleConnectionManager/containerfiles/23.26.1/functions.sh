#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2019 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: paramdeep.saini@oracle.com
# Description: Common functions for CMAN
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

export logdir="${logdir:-/tmp}"
export STD_OUT_FILE="${STD_OUT_FILE:-/proc/self/fd/1}"
export STD_ERR_FILE="${STD_ERR_FILE:-/proc/self/fd/2}"
export PROGNAME="${PROGNAME:-$(basename "${BASH_SOURCE[0]}")}"

resolve_logfile_path()
{
    local requested_file="${LOG_FILE:-${logfile:-}}"
    local requested_dir="${LOG_DIR:-}"

    if [ -n "$requested_file" ]; then
        printf '%s\n' "$requested_file"
        return 0
    fi

    if [ -n "$requested_dir" ]; then
        printf '%s/%s\n' "${requested_dir%/}" "cman-startup.log"
        return 0
    fi

    if [ -d /var/tmp ] && [ -w /var/tmp ]; then
        printf '%s\n' "/var/tmp/cman-startup.log"
    else
        printf '%s\n' "/tmp/cman-startup.log"
    fi
}

export logfile="$(resolve_logfile_path)"

init_logfile()
{
    local requested_file="${LOG_FILE:-${logfile:-}}"
    local requested_dir="${LOG_DIR:-}"
    local parent_dir

    logfile="$(resolve_logfile_path)"
    export logfile
    parent_dir="$(dirname "$logfile")"

    mkdir -p "$parent_dir" 2>/dev/null || true
    if touch "$logfile" 2>/dev/null; then
        return 0
    fi

    if [ "$logfile" != "/tmp/cman-startup.log" ]; then
        logfile="/tmp/cman-startup.log"
        export logfile
        mkdir -p /tmp 2>/dev/null || true
        touch "$logfile" 2>/dev/null || true
        if [ -n "$requested_file" ] || [ -n "$requested_dir" ]; then
            printf '%s\n' "$(timestamp_now) : ${PROGNAME} : Requested logfile path not writable, falling back to ${logfile}" > "$STD_OUT_FILE"
        fi
    fi
}

timestamp_now()
{
    date +"%m-%d-%Y %T %Z"
}

write_log_line()
{
    local message="$1"
    local stream_file="$2"

    init_logfile

    if [ -n "$logfile" ]; then
        printf '%s\n' "$message" >> "$logfile" 2>/dev/null || true
    fi

    printf '%s\n' "$message" > "$stream_file"
}

###### Function Related to printing messages and exit the script if error occurred ##################
error_exit()
{
    local now
    local message

    now="$(timestamp_now)"
    message="${now} : ${PROGNAME}: ${1:-Unknown Error}"
    write_log_line "$message" "$STD_ERR_FILE"
    exit 15
}

print_message()
{
    local now
    local message

    now="$(timestamp_now)"
    message="${now} : ${PROGNAME} : ${1:-Unknown Message}"
    write_log_line "$message" "$STD_OUT_FILE"
}

#####################################################################################################

####### Function related to IP Checks ###############################################################
resolve_host_ip()
{
    local host="$1"
    local ip=""

    if [ -z "$host" ]; then
        return 1
    fi

    ip=$(getent hosts "$host" | awk 'NR == 1 { print $1; exit }')
    if [ -z "$ip" ] && command -v nslookup >/dev/null 2>&1; then
        ip=$(nslookup "$host" 2>/dev/null | awk '/^Address: / { print $2 }' | tail -n 1)
    fi
    if [ -z "$ip" ] && command -v dig >/dev/null 2>&1; then
        ip=$(dig +short "$host" | awk 'NF { print; exit }')
    fi

    if [ -z "$ip" ]; then
        return 1
    fi

    printf '%s\n' "$ip"
}

resolveip()
{
    local host="$1"
    local ip=""

    ip="$(resolve_host_ip "$host")" || {
        print_message "unable to resolve '$host'"
        return 1
    }

    printf '%s\n' "$ip"
}
