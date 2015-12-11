#!/bin/bash
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

echo '# Maintainer: Bruno Borges <bruno.borges@oracle.com> (@brunoborges)'

for version in "${versions[@]}"; do
	commit="$(git log -1 --format='format:%H' "$version")"
	versionAliases=( $version ${aliases[$version]} )
	
	for va in "${versionAliases[@]}"; do
		echo "$va: ${url}@${commit} OpenJDK/$version"
	done
done

