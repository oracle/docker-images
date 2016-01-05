#!/bin/sh
# 
# Author: Bruno Borges <bruno.borges@oracle.com>
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
# 
set -e

declare -A aliases
aliases=(
    [jdk-8]='latest'
    [jdk-8]='jdk-8'
    [jdk-7]='jdk-7'
    [jdk-6]='jdk-6'
)

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )
url='git://github.com/oracle/docker-images'

echo '# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.'
echo '# Maintainer: Bruno Borges <bruno.borges@oracle.com> (@brunoborges)'

for version in "${versions[@]}"; do
	commit="$(git log -1 --format='format:%H' "$version")"
	versionAliases=( $version ${aliases[$version]} )
	
	for va in "${versionAliases[@]}"; do
		echo "$va: ${url}@${commit} OpenJDK/$version"
	done
done

