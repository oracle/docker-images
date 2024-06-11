#!/bin/bash
## Copyright (c) 2024, Oracle and/or its affiliates.
set -e

: "${INSTALLER:?}"

OGG_HOME="/u01/ogg"
ORA_HOME="/u01/app"
INSTALLER="/tmp/installer.zip"

##
##  Install the deployment from a "ShipHome" ZIP file
##

##
##  Terminate with an error message
##
function abort() {
	echo "Error - $*"
	exit 1
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
##  Unpack the OGG installation software
##
function ogg_installer_setup() {
	[[ -f "${INSTALLER}" ]] || abort "Source file '${INSTALLER}' does not exist"
	mkdir "/tmp/installer"
	unzip -q "${INSTALLER}" -d "/tmp/installer" || abort "Unzip operation failed for '${INSTALLER}'"
	chmod -R o=g-w "/tmp/installer"
}

##
## Get the INSTALL_OPTION.
##
function ogg_install_option() {
	local fastcopy_file
	fastcopy_file=$(find /tmp/installer -name fastcopy.xml -print -quit)
	[[ -z "${fastcopy_file}" ]] && abort "The file 'fastcopy.xml' could not be located."
	awk '/INSTALL_TYPE/ {
            sub(/^.*INSTALL_TYPE="/, "")
            sub(/".*/, "")
            print
            exit 0
        }' "${fastcopy_file}"
}

##
##  Perform an OGG installation
##
function ogg_install() {
	mkdir -p "${OGG_HOME}"
	chown -R ogg:ogg "$(dirname "${OGG_HOME}")"
	installer="$(find /tmp/installer -name runInstaller | head -1)"
	if [[ -n "${installer}" ]]; then
		cat <<EOF >"/tmp/installer.rsp"
oracle.install.responseFileVersion=/oracle/install/rspfmt_ogginstall_response_schema_v20_0_0
INSTALL_OPTION=${INSTALL_OPTION:-$(ogg_install_option)}
SOFTWARE_LOCATION=${OGG_HOME}
INVENTORY_LOCATION=${ORA_HOME}/oraInventory
UNIX_GROUP_NAME=ogg
EOF
		$(run_as_ogg) "${installer}" -silent -waitforcompletion -ignoreSysPrereqs -responseFile "/tmp/installer.rsp"
		"${ORA_HOME}/oraInventory/orainstRoot.sh"
	else
		$(run_as_ogg) tar xf /tmp/installer/*.tar -C "${OGG_HOME}"
	fi

	mkdir -p "${OGG_HOME}/scripts/"{setup,startup}
	chown -R ogg:ogg "${OGG_HOME}/scripts"

}

##
##  Installation
##
ogg_installer_setup
ogg_install
