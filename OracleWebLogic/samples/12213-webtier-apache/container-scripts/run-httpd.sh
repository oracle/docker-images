#!/bin/sh
set -e

# Apache gets grumpy about PID files pre-existing
rm -f /run/httpd/httpd.pid

exec httpd -DFOREGROUND
