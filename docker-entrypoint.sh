#!/bin/bash
set -e

if [ -z "$(ls -A data)" -a "$*" = 'mysqld_safe' ]; then
	./scripts/mysql_install_db --user=mysql
	chown -R mysql data
	cat > first-time.sql <<'EOF'
USE mysql;
UPDATE user SET host = "%" WHERE user = "root" LIMIT 1;
DELETE FROM user WHERE user = "root" AND host != "%";
FLUSH PRIVILEGES;
EOF
	exec "$@" --init-file="$(readlink -f first-time.sql)"
fi

exec "$@"
