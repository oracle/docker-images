#!/usr/bin/env sh

#!/bin/sh -e -x -u

# Copyright 2019, Oracle Corporation and/or its affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

trap "echo TRAPed signal" HUP INT QUIT KILL TERM

main()
    {
    COMMAND=server
    SCRIPT_NAME=$(basename "${0}")
    MAIN_CLASS="com.tangosol.net.DefaultCacheServer"

    case "${1}" in
        server) COMMAND=${1}; shift ;;
        console) COMMAND=${1}; shift ;;
        queryplus) COMMAND=queryPlus; shift ;;
        help) COMMAND=${1}; shift ;;
    esac

    case ${COMMAND} in
        server) server ;;
        console) console ;;
        queryPlus) queryPlus ;;
        help) usage; exit ;;
        *) server ;;
    esac
    }

# ---------------------------------------------------------------------------
# Display the help text for this script
# ---------------------------------------------------------------------------
usage()
    {
    echo "Usage: ${SCRIPT_NAME} [type] [args]"
    echo ""
    echo "type: - the type of process to run, must be one of:"
    echo "    server  - runs a storage enabled DefaultCacheServer"
    echo "              (server is the default if type is omitted)"
    echo "    console - runs a storage disabled Coherence console"
    echo "    query   - runs a storage disabled QueryPlus session"
    echo "    help    - displays this usage text"
    echo ""
    echo "args: - any subsequent arguments are passed as program args to the main class"
    echo ""
    echo "Environment Variables: The following environment variables affect the script operation"
    echo ""
    echo "JAVA_OPTS          - this environment variable adds Java options to the start command,"
    echo "                     for example memory and other system properties"
    echo ""
    echo "COH_WKA            - Sets the WKA address to use to discover a Coherence cluster."
    echo ""
    echo "COH_EXTEND_PORT    - If set the Extend Proxy Service will listen on this port instead"
    echo "                     of the default ephemeral port."
    echo ""
    echo "COH_METRICS_PORT   - If set, Coherence Metrics Http Service will listen on this port instead"
    echo "                     of the default port of 9612."
    echo ""
    echo "COH_MGMT_HTTP_PORT - If set, Coherence Management over HTTP Service will listen on this port instead"
    echo "                     of the default port of 30000."
    echo ""
    echo "Any jar files added to the /lib folder will be pre-pended to the classpath."
    echo "The /conf folder is on the classpath so any files in this folder can be loaded by the process."
    echo ""
    }

server()
    {
    # default to JDK logger for DCS
    PROPS="${PROPS} -Dcoherence.log=jdk -Dcoherence.log.logger=com.oracle.coherence -Djava.util.logging.config.file=${COHERENCE_HOME}/conf/logging.properties"
    # enable management over REST and metrics on their default ports
    PROPS="${PROPS} -Dcoherence.metrics.http.enabled=true -Dcoherence.management.http=all"
    MAIN_CLASS="com.tangosol.net.DefaultCacheServer"
    start
    }

console()
    {
    PROPS="${PROPS} -Dcoherence.localstorage=false"
    CLASSPATH="${CLASSPATH}:${COHERENCE_HOME}/lib/jline.jar"
    MAIN_CLASS="com.tangosol.net.CacheFactory"
    start
    }

queryPlus()
    {
    PROPS="${PROPS} -Dcoherence.localstorage=false"
    CLASSPATH="${CLASSPATH}:${COHERENCE_HOME}/lib/jline.jar"
    MAIN_CLASS="com.tangosol.coherence.dslquery.QueryPlus"
    start
    }

start()
    {
    if [ "${COH_WKA}" != "" ]
    then
       PROPS="${PROPS} -Dcoherence.wka=${COH_WKA}"
    fi

    if [ "${COH_EXTEND_PORT}" != "" ]
    then
       PROPS="${PROPS} -Dcoherence.cacheconfig=extend-cache-config.xml -Dcoherence.extend.port=${COH_EXTEND_PORT}"
    fi

    if [ "${COH_METRICS_PORT}" != "" ]
    then
        PROPS="${PROPS} -Dcoherence.metrics.http.port=${COH_METRICS_PORT}"
    fi

    if [ "${COH_MGMT_HTTP_PORT}" != "" ]
    then
        PROPS="${PROPS} -Dcoherence.management.http.port=${COH_MGMT_HTTP_PORT}"
    fi

    if [ "${COH_SITE_INFO_LOCATION}" != "" ]
    then
        case "${COH_SITE_INFO_LOCATION}" in
            http://\$*)
                SITE=""
                break;;
            http://*)
                SITE=$(curl ${COH_SITE_INFO_LOCATION})
                if [ $? != 0 ]
                then
                    SITE=""
                fi
                break;;
            *)
                if [ -f "${COH_SITE_INFO_LOCATION}" ]
                then
                    SITE=`cat ${COH_SITE_INFO_LOCATION}`
                fi
        esac

        if [ -n "${SITE}" ]
        then
            PROPS="${PROPS} -Dcoherence.site=${SITE}"
        fi
    fi

    CLASSPATH="${COHERENCE_HOME}/ext/conf:${COHERENCE_HOME}/ext/lib/*:${CLASSPATH}:${COHERENCE_HOME}/conf:${COHERENCE_HOME}/lib/coherence.jar:${COHERENCE_HOME}/lib/coherence-management.jar:${COHERENCE_HOME}/lib/coherence-metrics.jar:${DEPENDENCY_MODULES}/*"

    CMD="${JAVA_HOME}/bin/java -cp ${CLASSPATH} ${PROPS} ${JAVA_OPTS} ${MAIN_CLASS} ${COH_MAIN_ARGS}"

    echo "Starting Coherence ${COMMAND} using ${CMD}"

    exec ${CMD}
    }

main "$@"
