#!/bin/bash
## Copyright (c) 2024, Oracle and/or its affiliates.
set -e

##
##  Execute OGG Deployment
##

##
##  Terminate with an error message
##
function abort() {
	echo "Error - $*"
	exit 1
}

: "${OGG_DEPLOYMENT:=Local}"
: "${OGG_ADMIN:=oggadmin}"
: "${OGG_LISTEN_ON:=127.0.0.1}"

: "${OGG_DEPLOYMENT_HOME:?}"
[[ -d "${OGG_DEPLOYMENT_HOME}" ]] || abort "Deployment storage, '${OGG_DEPLOYMENT_HOME}', not found."
: "${OGG_TEMPORARY_FILES:?}"
[[ -d "${OGG_TEMPORARY_FILES}" ]] || abort "Deployment temporary storage, '${OGG_TEMPORARY_FILES}', not found."
: "${OGG_HOME:?}"
[[ -d "${OGG_HOME}" ]] || abort "Deployment runtime, '${OGG_HOME}'. not found."

: "${OGG_DEPLOYMENT_SCRIPTS:?}"
[[ -d "${OGG_DEPLOYMENT_SCRIPTS}" ]] || abort "OGG deployment scripts storage, '${OGG_DEPLOYMENT_SCRIPTS}', not found."

NGINX_CRT="$(awk '$1 == "ssl_certificate"     { gsub(/;/, ""); print $NF; exit }' </etc/nginx/nginx.conf)"
NGINX_KEY="$(awk '$1 == "ssl_certificate_key" { gsub(/;/, ""); print $NF; exit }' </etc/nginx/nginx.conf)"

export OGG_DEPLOYMENT OGG_ADMIN NGINX_CRT NGINX_KEY

##
##  If not already specified, generate a random password with:
##  - at least one uppercase character
##  - at least one lowercase character
##  - at least one digit character
##
function generatePassword {
	if [[ -n "${OGG_ADMIN_PWD}" || -d "${OGG_DEPLOYMENT_HOME}/Deployment/etc" ]]; then
		return
	fi
	local password
	password="$(openssl rand -base64 9)-$(openssl rand -base64 3)"
	if [[ "${password}" != "${password/[A-Z]/_}" &&
		"${password}" != "${password/[a-z]/_}" &&
		"${password}" != "${password/[0-9]/_}" ]]; then
		export OGG_ADMIN_PWD="${password}"
		echo "----------------------------------------------------------------------------------"
		echo "--  Password for OGG administrative user '${OGG_ADMIN}' is '${OGG_ADMIN_PWD}'"
		echo "----------------------------------------------------------------------------------"
		return
	fi
	generatePassword
}

##
##  Locate the Java installation and set JAVA_HOME
##
function locate_java() {
	[[ -n "${JAVA_HOME}" ]] && return 0

	local java
	java=$(command -v java)
	[[ -z "${java}" ]] && abort "Java installation not found"

	JAVA_HOME="$(dirname "$(dirname "$(readlink -f "${java}")")")"
	export JAVA_HOME
}

##
##  Locate the shared library libjvm.so and set LD_LIBRARY_PATH
##
function locate_lib_jvm() {
	[[ -z "${JAVA_HOME}" ]] && abort "Java installation not found"

	local libjvm
	libjvm="$(find "${JAVA_HOME}" -name libjvm.so | head -1)"
	if [ -z "${libjvm}" ]; then
		echo "Warning: The shared library libjvm.so cannot be located."
	else
		local JVM_LIBRARY_PATH
		JVM_LIBRARY_PATH="$(dirname "${libjvm}")"
		export LD_LIBRARY_PATH=$JVM_LIBRARY_PATH:$LD_LIBRARY_PATH
	fi
}

##
##  Return a string used for running a process as the 'ogg' user
##
function run_as_ogg() {
	local user="ogg"
	local uid gid
	uid="$(id -u "${user}")"
	gid="$(id -g "${user}")"
	echo "setpriv --ruid ${uid} --euid ${uid} --groups ${gid} --rgid ${gid} --egid ${gid} -- "
}

##
##  Create and set permissions for directories for the deployment
##
function setup_deployment_directories() {
	rm -fr "${OGG_DEPLOYMENT_HOME}"/Deployment/var/{run,temp,lib/db} \
		"${OGG_TEMPORARY_FILES}"/{run,temp}
	mkdir -p "${OGG_TEMPORARY_FILES}"/{run,temp,db} \
		"${OGG_DEPLOYMENT_HOME}"/Deployment/var/lib
	ln -s "${OGG_TEMPORARY_FILES}"/run "${OGG_DEPLOYMENT_HOME}"/Deployment/var/run
	ln -s "${OGG_TEMPORARY_FILES}"/temp "${OGG_DEPLOYMENT_HOME}"/Deployment/var/temp
	ln -s "${OGG_TEMPORARY_FILES}"/db "${OGG_DEPLOYMENT_HOME}"/Deployment/var/lib/db

	chown ogg:ogg "${OGG_DEPLOYMENT_HOME}" "${OGG_TEMPORARY_FILES}"
	chmod 0750 "${OGG_DEPLOYMENT_HOME}" "${OGG_TEMPORARY_FILES}"
	find "${OGG_DEPLOYMENT_HOME}" "${OGG_TEMPORARY_FILES}" -mindepth 1 -maxdepth 1 -not -name '.*' -exec \
		chown -R ogg:ogg {} \;
}

##
##  Run custom scripts in the container before and after GoldenGate starts
##
function run_user_scripts {
	local scripts="${1}"
	while read -r script; do
		case "${script}" in
		*.sh)
			echo "Running shell script '${script}'"
			# shellcheck disable=SC1090
			source "${script}"
			;;
		*.py)
			echo "Running Python script '${script}'"
			python3 "${script}"
			;;
		*)
			echo "Ignoring '${script}'"
			;;
		esac
	done < <(find "${scripts}" -type f | sort)
}

##
##  Initialize and start the OGG installation
##
function start_ogg() {
	$(run_as_ogg) python3 /usr/local/bin/deployment-init.py
	$(run_as_ogg) tail -F "${OGG_DEPLOYMENT_HOME}"/ServiceManager/var/log/ServiceManager.log &
	ogg_pid=$!
}

##
##  Start the reverse proxy daemon
##
function start_nginx() {
	[[ ! -f "${NGINX_CRT}" || ! -f "${NGINX_KEY}" ]] && {
		/usr/local/bin/create-certificate.sh
	}
	replace-variables.sh /etc/nginx/*.conf
	/usr/sbin/nginx -t
	/usr/sbin/nginx
}

##
##  Termination handler
##
function termination_handler() {
	[[ -z "${ogg_pid}" ]] || {
		kill "${ogg_pid}"
		unset ogg_pid
	}
	[[ ! -f "/var/run/nginx.pid" ]] || {
		/usr/sbin/nginx -s stop
	}
	exit 0
}

##
##  Signal Handling for this script
##
function signal_handling() {
	trap - SIGTERM SIGINT
	trap termination_handler SIGTERM SIGINT
}

##
##  Entrypoint
##
generatePassword
run_user_scripts "${OGG_DEPLOYMENT_SCRIPTS}/setup"
setup_deployment_directories
locate_java
locate_lib_jvm
start_ogg
start_nginx
signal_handling
run_user_scripts "${OGG_DEPLOYMENT_SCRIPTS}/startup"
wait
