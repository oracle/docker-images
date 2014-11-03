#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

for version in "${versions[@]}"; do
	fullVersion="$(curl -sSL "https://dev.mysql.com/downloads/mysql/$version.html?os=2" \
		| grep '">(mysql-'"$version"'.*-linux.*-x86_64\.tar\.gz)<' \
		| sed -r 's!.*\(mysql-([^<)]+)-linux.*-x86_64\.tar\.gz\).*!\1!' \
		| sort -V | tail -1)"
	
	(
		set -x
		sed -ri '
			s/^(ENV MYSQL_MAJOR) .*/\1 '"$version"'/;
			s/^(ENV MYSQL_VERSION) .*/\1 '"$fullVersion"'/
		' "$version/Dockerfile"
	)
done
