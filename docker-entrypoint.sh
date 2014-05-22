#!/bin/bash
set -e

if [ -z "$(ls -A data)" -a "$*" = 'mysqld_safe' ]; then
	if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
		echo >&2 'error: database is uninitialized and MYSQL_ROOT_PASSWORD not set'
		echo >&2 '  Did you forget to add -e MYSQL_ROOT_PASSWORD=... ?'
		exit 1
	fi
	./scripts/mysql_install_db --user=mysql
	chown -R mysql data
	# TODO proper SQL escaping on dat root password D:
	cat > first-time.sql <<EOF
USE mysql;

UPDATE user
SET host = "%",
	password = PASSWORD("${MYSQL_ROOT_PASSWORD}")
WHERE user = "root"
LIMIT 1;

DELETE FROM user
WHERE user = "root"
	AND host != "%";

FLUSH PRIVILEGES;
EOF
	exec "$@" --init-file="$(readlink -f first-time.sql)"
fi

exec "$@"
