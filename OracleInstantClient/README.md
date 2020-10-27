# About this Container Image

These container images are for the Oracle Instant Client 'Basic', 'SDK' and 'SQL\*Plus' packages.  They can be used to build and run Oracle Call Interface (OCI), Oracle C++ Call Interface (OCCI), and JDBC-OCI applications applications.  The SQL\*Plus command-line query tool allows quick ad-hoc SQL and PL/SQL execution.  The container images can be extended with optional packages for ODBC, or to include tools such as Oracle SQL\*Loader.

The base images support building and using scripting language APIs that internally call OCI.  These include [Python's cx_Oracle](https://yum.oracle.com/oracle-linux-python.html), [Node.js's node-oracledb](https://yum.oracle.com/oracle-linux-nodejs.html), [PHP's OCI8](https://yum.oracle.com/oracle-linux-php.html), [Go's goracle](https://github.com/go-goracle/goracle) and [Ruby's ruby-oci8](https://www.rubydoc.info/github/kubo/ruby-oci8).

## About Oracle Instant Client

The [Oracle Instant Client](https://www.oracle.com/technetwork/database/features/instant-client/) is a repackaging of Oracle Database libraries, tools and header files usable to create and run applications that connect to a remote (or local) Oracle Database.

Oracle client-server version interoperability is detailed in [Doc ID 207303.1](https://support.oracle.com/epmos/faces/DocumentDisplay?id=207303.1).  In summary, applications using Oracle Call Interface (OCI) 19, 18 and 12.2 can connect to Oracle Database 11.2 or later.  Some tools may have other restrictions.

From release 18.3, the Oracle Instant Client RPMs for Oracle Linux are available for direct download from the [Oracle Linux yum server](https://yum.oracle.com) without requiring manual license acceptance.

## Building the Oracle Instant Client 19 Image

Change directory to [`dockerfiles/19`](dockerfiles/19) and run:

```
docker build --pull -t oracle/instantclient:19 .
```

The build process automatically installs Instant Client using RPMs directly from the [Oracle Instant Client repository](https://yum.oracle.com/repo/OracleLinux/OL7/oracle/instantclient/x86_64/index.html) on the [Oracle Linux yum server](https://yum.oracle.com).

Applications using Oracle Call Interface (OCI) 19 can connect to
Oracle Database 11.2 or later.  Some tools may have other
restrictions.

## Building the Oracle Instant Client 18 Image

Change directory to [`dockerfiles/18`](dockerfiles/18) and run:

```
docker build --pull -t oracle/instantclient:18 .
```

The build process will automatically install the Instant Client using RPMs sourced directly from the [Oracle Instant Client repository](https://yum.oracle.com/repo/OracleLinux/OL7/oracle/instantclient/x86_64/index.html) on the [Oracle Linux yum server](https://yum.oracle.com).

Applications using Oracle Call Interface (OCI) 18 can connect to
Oracle Database 11.2 or later.  Some tools may have other
restrictions.

## Building the Oracle Instant Client 12.2 Image

Download the following three RPMs from the [Instant Client download page](https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html) on the Oracle Technology Network:

- `oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm`
- `oracle-instantclient12.2-devel-12.2.0.1.0-1.x86_64.rpm`
- `oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm`

Place the downloaded Oracle Instant Client RPMs (from the previous step) in the
[`dockerfiles/12.2.0.1`](dockerfiles/12.2.0.1) directory, then switch to that directory and run:

```
docker build --pull -t oracle/instantclient:12.2.0.1 .
```

Applications using Oracle Call Interface (OCI) 12.2 can connect to
Oracle Database 11.2 or later.  Some tools may have other
restrictions.

## Running a Container

These Dockerfiles include SQL\*Plus so you can interactively run a container to
execute ad-hoc SQL and PL/SQL statements against your database, for example:

```
docker run -ti --rm oracle/instantclient:19 sqlplus hr@example.com/orclpdb1
```

## Optional Oracle Net and Oracle Client Configuration Files

Optional Oracle Network and Oracle client configuration files can be
copied or mounted to the default configuration file directory
`/usr/lib/oracle/<version>/client64/lib/network/admin`.  Optional
files include `tnsnames.ora`, `sqlnet.ora`, `oraaccess.xml` and
`cwallet.sso`.

When files are in the default directory, you do **not** need to set
Oracle's `TNS_ADMIN` environment variable.

For Instant Client 12.2, and earlier, you must explicitly create the
directory.

## Using Wallets with Instant Client

Oracle Wallets allow database connection over TLS and/or without requiring
database credentials.

To use a wallet with Instant Client, obtain your wallet files and place them in
a secure host directory.  Then, when running a container, use a volume to mount
the files to the default Instant Client network configuration file directory,
for example:

```
docker run -v /my/host/wallet_dir:/usr/lib/oracle/19.9/client64/lib/network/admin:Z,ro . . .
```

You should review which volume options are required.  The `Z` option is needed
when selinux is in effect, see "Configure the selinux label" in [Use bind
mounts](https://docs.docker.com/storage/bind-mounts/).

If you have a wallet zip downloaded from an Oracle Cloud Database then you
should unzip it and, in this example, place the extracted files in
`/my/host/wallet_dir` on your host.  Cloud database wallets provide connection
strings for the database service and enable TLS.  Your container applications
should use one of the connection strings from `tnsnames.ora` and also supply a
valid database username and password for connection.  If you are using C based
applications (including database drivers for Python, Node.js, Go, Ruby or PHP)
you only need the `tnsnames.ora`, `sqlnet.ora` and `cwallet.sso` files from the
zip file.  Keep the files secure.

## Adding Oracle Database Drivers

To extend the image with optional Oracle Database drivers, follow your desired driver installation steps.  The Instant Client libraries are in `/usr/lib/oracle/<version>/client64/lib` and the Instant Client headers are in `/usr/include/oracle/<version>/client64/`.

The Instant Client libraries are in the default library search path.
