#!/bin/bash
## Copyright (c) 2022, Oracle and/or its affiliates.
set -e

: "${INSTALLER:?}"

OGG_HOME="/u01/ogg"
ORA_HOME="/u01/app"
INSTALLER="/tmp/installer.zip"

##
##  i n s t a l l - d e p l o y m e n t . s h
##  Install the deployment from a "ShipHome" ZIP file
##

##
##  a b o r t
##  Terminate with an error message
##
function abort() {
    echo "Error - $*"
    exit 1
}

##
##  r u n _ a s _ o g g
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
##  o g g _ i n s t a l l e r _ s e t u p
##  Unpack the OGG installation software
##
function ogg_installer_setup() {
    [[ -f "${INSTALLER}" ]]                     || abort "Source file '${INSTALLER}' does not exist"
    mkdir "/tmp/installer"
    unzip -q "${INSTALLER}" -d "/tmp/installer" || abort "Unzip operation failed for '${INSTALLER}'"
    chmod -R o=g-w             "/tmp/installer"
}
##
##
## o g g _ i n s t a l l _ o p t i o n
##
function ogg_install_option() {
    # Get the path to the fastcopy.xml file that contains the metadata for the install option.
    local fast_copy_file
    fast_copy_file=$(find /tmp/installer -name fastcopy.xml)

    # Get the xml line that needs to be parsed.
    local xml_line
    xml_line=$(grep -h 'TOPLEVEL_COMPONENT NAME' "${fast_copy_file}")

    # Match string example:   <TOPLEVEL_COMPONENT NAME="oracle.oggcore.services" INSTALL_TYPE="ora21c" PLATFORM="Linux">
    local regex
    regex='.*<TOPLEVEL_COMPONENT NAME=.* INSTALL_TYPE="(.*)" .*'

    [[ $xml_line =~ $regex ]]                     || abort "Could not find INSTALL_TYPE in the file '${fast_copy_file}'"
    echo "${BASH_REMATCH[1]}"
}

##
##  o g g _ i n s t a l l
##  Perform an OGG installation
##
function ogg_install() {
    mkdir -p         "${OGG_HOME}"
    chown -R ogg:ogg "$(dirname "${OGG_HOME}")"
    installer="$(find /tmp/installer -name runInstaller | head -1)"
    if [[ -n "${installer}" ]]; then
        cat<<EOF >"/tmp/installer.rsp"
oracle.install.responseFileVersion=/oracle/install/rspfmt_ogginstall_response_schema_v20_0_0
INSTALL_OPTION=$(ogg_install_option)
SOFTWARE_LOCATION=${OGG_HOME}
INVENTORY_LOCATION=${ORA_HOME}/oraInventory
UNIX_GROUP_NAME=ogg
EOF
        $(run_as_ogg) "${installer}" -silent -waitforcompletion -ignoreSysPrereqs -responseFile "/tmp/installer.rsp"
        "${ORA_HOME}/oraInventory/orainstRoot.sh"
    else
        $(run_as_ogg) tar xf /tmp/installer/*.tar -C "${OGG_HOME}"
    fi
}

##
##  Installation
##
ogg_installer_setup
ogg_install
