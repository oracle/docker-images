# About this Docker Image

These Docker images contain the Oracle Instant Client 'Basic', 'SDK' and 'SQL*Plus' packages.  They can be extended to run Oracle Call Interface (OCI), Oracle C++ Call Interface (OCCI) and JDBC applications.  They can also be extended to build and run scripting language drivers that use OCI such as Python's cx_Oracle, Node.js's node-oracledb, PHP's OCI8, and Ruby's ruby-oci8.  

The SQL*Plus command-line query tool is also included, allowing quick ad-hoc SQL and PL/SQL execution.

## About Oracle Instant Client

The [Oracle Instant Client](http://www.oracle.com/technetwork/database/features/instant-client/) is a repackaging of Oracle Database libraries, tools and header files usable to create and run applications that connect to a remote (or local) Oracle Database.

Oracle client-server version interoperability is detailed in [Doc ID 207303.1](https://support.oracle.com/epmos/faces/DocumentDisplay?id=207303.1).  Applications using Oracle Call Interface (OCI) 18.3 and 12.2 can connect to Oracle Database 11.2 or later.  Some tools may have other restrictions.

From release 18.3, the Oracle Instant Client RPMs for Oracle Linux are available for direct download from the [Oracle Linux yum server](https://yum.oracle.com) without requiring manual license acceptance.

## Building the Oracle Instant Client 18.3 Image

Change directory to [`dockerfiles/18.3.0`](dockerfiles/18.3.0) and run:

```
docker build -t oracle/instantclient:18.3.0
```

The build process will automatically install the Instant Client using RPMs sourced directly from the [Oracle Instant Client repository](http://yum.oracle.com/repo/OracleLinux/OL7/oracle/instantclient/x86_64/index.html) on the [Oracle Linux yum server](https://yum.oracle.com).

## Building the Oracle Instant Client 12.2 Image

Download the following three RPMs from the [Instant Client download page](http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html) on the Oracle Technology Network:

- `oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm`
- `oracle-instantclient12.2-devel-12.2.0.1.0-1.x86_64.rpm`
- `oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm`

Place the downloaded Oracle Instant Client RPMs (from the previous step) in the
[`dockerfiles/12.2.0.1`](dockerfiles/12.2.0.1) directory, then switch to that directory and run:

```
docker build -t oracle/instantclient:12.2.0.1 .
```

## Usage

You can run a container interactively to execute ad-hoc SQL and PL/SQL statements in SQL*Plus:

```
docker run -ti --rm oracle/instantclient:18.3.0 sqlplus hr/welcome@example.com/pdborcl
```

## Adding Oracle Database Drivers

To extend the image with optional Oracle Database drivers, follow your desired driver installation steps.  The Instant Client libraries are in `/usr/lib/oracle/<version>/client64/lib` and the Instant Client headers are in `/usr/include/oracle/<version>/client64/`.

The Instant Client libraries are in the default library search path.
