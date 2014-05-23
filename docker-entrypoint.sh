#!/bin/bash
set -e

if [ -z "$(ls -A /var/lib/mysql)" -a "$1" = 'mysqld_safe' ]; then
	if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
		echo >&2 'error: database is uninitialized and MYSQL_ROOT_PASSWORD not set'
		echo >&2 '  Did you forget to add -e MYSQL_ROOT_PASSWORD=... ?'
		exit 1
	fi
	
	mysql_install_db --datadir=/var/lib/mysql
	chown -R mysql:mysql /var/lib/mysql
	
	# TODO proper SQL escaping on dat root password D:
	cat > first-time.sql <<EOF
USE mysql;

UPDATE user
SET host = "%",
	password = PASSWORD("${MYSQL_ROOT_PASSWORD}")
WHERE user = "root"
LIMIT 1;

DELETE FROM user
WHERE user != "root"
	OR host != "%";

DROP DATABASE IF EXISTS test;

FLUSH PRIVILEGES;
EOF
	exec "$@" --init-file="$(readlink -f first-time.sql)"
fi

exec "$@"
