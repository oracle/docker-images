#!/bin/bash
## Copyright (c) 2024, Oracle and/or its affiliates.
set -e

##
##  Installation of prerequisite software
##

packages=(java-17-openjdk jq libaio libnsl nginx perl python39 python39-requests python39-psutil tar unzip xz)
packages+=(unixODBC libpq) ## Required for PostgreSQL

function success() {
	echo "Packages installed after ${sequence} attempts"
	rm -rf /var/cache/yum /var/log/yum* /tmp/yum*
	useradd ogg
	exit 0
}

##  Attempt the module and package installation up to three times
##  in case there are network issues that cause failures.
for sequence in $(seq 3); do
	dnf -y module enable nginx:1.22 python39 &&
		dnf -y install "${packages[@]}" && success "${sequence}"
done
exit 1
