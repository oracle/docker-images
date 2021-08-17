# LICENSE UPL 1.0
#
# Copyright (c) 2021, Oracle and/or its affiliates. All rights reserved.
#
# Container image template for Oracle Instant Client
#
# HOW TO BUILD THIS IMAGE AND RUN A CONTAINER
# --------------------------------------------
#
# Execute:
#      $ docker build --pull -t oraclelinux8-instantclient:21 .
#      $ docker run -ti --rm oraclelinux8-instantclient:21 sqlplus /nolog
#
# NOTES
# -----
#
# Applications using Oracle Call Interface (OCI) 21 can connect to
# Oracle Database 12.1 or later.  Some tools may have other
# restrictions.
#
# Oracle Instant Client 21 automatically configures the global library search
# path to include Instant Client libraries.
#
# OPTIONAL ORACLE CONFIGURATION FILES
# -----------------------------------
#
# Optional Oracle Network and Oracle client configuration files can be put in the
# default configuration file directory /usr/lib/oracle/21/client64/lib/network/admin.
# Configuration files include tnsnames.ora, sqlnet.ora, oraaccess.xml and
# cwallet.sso.  You can use a Docker volume to mount the directory containing
# the files at runtime, for example:
#
#   docker run -v /my/host/wallet_dir:/usr/lib/oracle/21/client64/lib/network/admin:Z,ro . . .
#
# This avoids embedding private information such as wallets in images.  If you
# do choose to include network configuration files in images, you can use a
# Dockerfile COPY, for example:
#
#   COPY tnsnames.ora sqlnet.ora /usr/lib/oracle/21/client64/lib/network/admin/
#
# There is no need to set the TNS_ADMIN environment variable when files are in
# the container's default configuration file directory, as shown.
#
# ORACLE INSTANT CLIENT PACKAGES
# ------------------------------
#
# Instant Client 21 Packages for Oracle Linux 8 are available from
#   https://yum.oracle.com/repo/OracleLinux/OL8/oracle/instantclient21/x86_64/
# Also see https://yum.oracle.com/oracle-instant-client.html
#
# Base - one of these packages is required to run applications and tools
#   oracle-instantclient-basic      : Basic Package - All files required to run OCI, OCCI, and JDBC-OCI applications
#   oracle-instantclient-basiclite  : Basic Light Package - Smaller version of the Basic package, with only English error messages and Unicode, ASCII, and Western European character set support
#
# Tools - optional packages (requires the 'basic' package)
#   oracle-instantclient-sqlplus    : SQL*Plus Package - The SQL*Plus command line tool for SQL and PL/SQL queries
#   oracle-instantclient-tools      : Tools Package - Includes Data Pump, SQL*Loader and Workload Replay Client
#
# Development and Runtime - optional packages (requires the 'basic' package)
#   oracle-instantclient-devel      : SDK Package - Additional header files and an example makefile for developing Oracle applications with Instant Client
#   oracle-instantclient-jdbc       : JDBC Supplement Package - Additional support for Internationalization under JDBC
#   oracle-instantclient-odbc       : ODBC Package - Additional libraries for enabling ODBC applications
#
# PREBUILT CONTAINER
# ------------------
#
# A prebuilt container from this Dockerfile is available from
#   https://github.com/orgs/oracle/packages/container/package/oraclelinux8-instantclient
# and can be pulled with:
#   docker pull ghcr.io/oracle/oraclelinux8-instantclient:21

FROM oraclelinux:8

RUN  dnf -y install oracle-instantclient-release-el8 && \
     dnf -y install oracle-instantclient-basic oracle-instantclient-devel oracle-instantclient-sqlplus && \
     rm -rf /var/cache/dnf

# Uncomment if the tools package is added
# ENV PATH=$PATH:/usr/lib/oracle/21/client64/bin

CMD ["sqlplus", "-v"]
