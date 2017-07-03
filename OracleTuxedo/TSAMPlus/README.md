Oracle TSAM Plus on Docker
===============
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users. This image has also been certified with [Oracle Container Cloud Service (OCCS)](https://cloud.oracle.com/container). For more information about **Oracle Tuxedo System and Applications Monitor Plus (TSAM Plus)** please see the [Oracle TSAM Plus Online Documentation](http://docs.oracle.com/cd/E72452_01/tsam/docs1222/index.html).

This project offers Dockerfile for building:
 * Oracle TSAM Plus 12c Release 2 (12.2.2)

## Dependencies
This project depends on the [Oracle Server JRE 8 Docker Image](../../OracleJava). So, before you proceed to build this image, make sure the image `oracle/serverjre:8` has been built locally or is accessible in a remote Docker registry.

**IMPORTANT:** You will have to provide the required installation binaries and put them into the `dockerfiles/<version>` folder.

For this image following installation media / binaries are required:

* [Oracle TSAM Plus 12.2.2 GA Installer](http://www.oracle.com/technetwork/middleware/tuxedo/downloads/index.html) - `tsam122200_64_Linux_x86.zip`
* [Oracle Database Instant Client](http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html) - `oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm` and `oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm`

The download links and `md5sum` of downloaded binaries could also be found in the `.download` files inside the `dockerfiles/<version>` folder. Note that the downloaded file names must **NOT** be changed, they should remain the same with the file names mentioned in the `.download` files.

## Building Oracle TSAM Plus Docker Install Images
Once you have provided the installation binaries and put them into the right folder (`dockerfiles/<version>`), go into it and run:

```bash
docker build -t oracle/tsam:12.2.2 .
```

Since during the image building new packages required by this image will be installed by the `yum` repository manager, access to internet should be available. If you are building the image behind a HTTP proxy server, use below command:

```bash
docker build \
   --build-arg http_proxy=http://<hostname>:<port> \
   --build-arg https_proxy=http://<hostname>:<port> \
   -t oracle/tsam:12.2.2 .
```

> It is recommended to give read permission to all users on the downloaded binary files before building the image. Otherwise the resulting image will most probably get 1.7G larger.

**IMPORTANT:** The resulting image will be an image with the **Oracle TSAM Plus 12.2.2** installed. On first startup of the container a new Oracle WebLogic domain will be created, followed by which the **TSAM Manager** application will be deployed into the domain.

### Applying Rolling Patch to the Base Image
By building the Docker image with the primary `Dockerfile` in the `dockerfiles/<version>` directory, you got an image with corresponding TSAM GA release installed. If you are a supported customer of Oracle TSAM Plus, you'll be able to download and apply rolling patches to the base installation to benefit from the latest product enhancements and bug fixes.

To build the Docker image with rolling patch applied, check the sample in [samples/apply-patch](samples/apply-patch/) directory for more detail.

## Running Oracle TSAM Plus in a Docker container
The **TSAM Manager** application relies on a remote Oracle Database to run. So, on starting of the container, the required information need to be passed into the container by a set of environment variables, e.g. The database connection string, credentials, table space, Oracle WebLogic domain admin password, etc. The easiest way to do this is through the `docker-compose` command. For more information about `docker-compose`, check the Docker Compose [online documentation](https://docs.docker.com/compose/overview).

### Running Oracle TSAM Plus with new TSAM database schema created
This is the typical scenario to use the Docker image. By providing the new Oracle Database instance connection information and the `sys` user credentials, the entire TSAM database schema will be created on initializing the container.

A sample `docker-compose.yml` file is as below:

```yaml
version: "2"
services:
  tsam:
    image: oracle/tsam:12.2.2
    hostname: tsam.docker
    ports:
      - 7001/tcp
      - 22/tcp
    privileged: true
    environment:
      - "DB_CONNSTR=db.box:1521/orcl"
      - "DB_TSAM_USER=tsam"
      - "DB_TSAM_PASSWD=tsam"
      - "TSAM_CONSOLE_ADMIN_PASSWD=admin1"
      - "DBA_USER=sys"
      - "DBA_PASSWD=welcome1"
      - "DB_TSAM_TBLSPACE=users"
      - "WLS_PW=weblogic1"
```

The environment variables are explained as follow:

* `DB_CONNSTR` The Oracle Database instance connection string, in the format of `<hostname>:<port>/<svcname>`. When using the database instance provisioned by **Oracle Database Cloud Service**, it is the **Connect String** in the **Database** section on the instance home page. Please pay attention that the last part `<svcname>` is the **service name** of the database instance, other than **SID**.
* `DB_TSAM_USER` The new database user to be created. Please note if the user has already been existed in the database instance, and also the followed `DB_TSAM_PASSWD` is correctly provided, this user will be used as the TSAM database user directly without re-create or overwrite.
* `DB_TSAM_PASSWD` The password of the TSAM database user.
* `TSAM_CONSOLE_ADMIN_PASSWD` The password of TSAM Manager console `admin` user. On successful initializing of the TSAM container, the TSAM console should be available at `http://<container_ip_address>:<wls_adm_svr_port>/tsam`. On the TSAM console login page, user name `admin` and this password will be used as the login credential.
* `DBA_USER` The Oracle Database DBA username, typically it's `sys`.
* `DBA_PASSWD` Password of database `sys` user.
* `DB_TSAM_TBLSPACE` The tablespace in which the new TSAM database user will be created. For testing purpose, it would be OK to just use the `users` tablespace.
* `WLS_PW` The admin user password of new created Oracle WebLogic domain.

To start the container, simply run below command in the same directly where above `docker-compose.yml` file resides.

```bash
docker-compose up
```

> When running the container in a **Oracle Container Cloud Service** instance, just paste above `docker-compose.yml` file content into the **YAML** tab of the **Service Editor** on creating a container service.

Besides the above environment variables which are required, there are also some optional ones could be used to provide more control on the container.

* `DEBUG_MODE` Whether or not to turn on debug mode. The value is either `true` or `false` (default). When the debug mode is turned on, more debug messages will be printed out to the container stdout. For example, the passed in environment variables and corresponding values, the Oracle WebLogic domain startup log, etc. Furthermore, when debug is on, the container will never terminate even though error is occurred during the container initialization. While in the normal mode, the container terminates after 120 seconds on failure.
* `DB_ENABLE_PARTITION` Whether or not to enable the Oracle Database Partitioning feature. The value is either `yes` or `no` (default). Please note only when a Oracle Database Enterprise Edition is being used, the database partitioning could be turned on. So for a Standard Edition or XE database, the value could only be `no`.
* `ADMIN_PORT` The new created WebLogic domain Admin Server HTTP listening port, default is `7001`.
* `ADMIN_SSL_PORT` The new created WebLogic domain Admin Server HTTPS listening port, default is `7002`.
* `WLS_USER` The new created WebLogic domain admin user name, default is `weblogic`.
* `DOMAIN_NAME` The new created WebLogic domain name, default is `tsamdomain`.

### Running Oracle TSAM Plus with an existing TSAM database schema
When an existing TSAM database is used for the TSAM Manager application, there will be no need to provide Oracle Database `sys` user related credentials. The `docker-compose.yml` looks like below:

```yaml
version: "2"
services:
  tsam:
    image: oracle/tsam:12.2.2
    hostname: tsam.docker
    ports:
      - 7001/tcp
      - 22/tcp
    privileged: true
    environment:
      - "DB_CONNSTR=db.box:1521/orcl"
      - "DB_TSAM_USER=tsam"
      - "DB_TSAM_PASSWD=tsam"
      - "TSAM_CONSOLE_ADMIN_PASSWD=admin1"
      - "WLS_PW=weblogic1"
```

> Note that the existing database schema used should be created by a TSAM Plus Manager installation with the same patch level, or else the application could behave abnormally.

### Running Oracle TSAM Plus with an database Docker container
If you got an Oracle Database Docker image, you can run it together with the TSAM container to provide the database service. The `docker-compose.yml` file will look like this:

```yaml
version: "2"
services:
  db:
    image: oracle-database-image
    hostname: db.box
    ports:
      - 1521/tcp
  tsam:
    image: oracle/tsam:12.2.2
    hostname: tsam.docker
    ports:
      - 7001/tcp
      - 22/tcp
    environment:
      - "DB_CONNSTR=db.box:1521/orcl"
      - "DB_TSAM_USER=tsam"
      - "DB_TSAM_PASSWD=tsam"
      - "TSAM_CONSOLE_ADMIN_PASSWD=admin1"
      - "DBA_USER=sys"
      - "DBA_PASSWD=welcome1"
      - "DB_TSAM_TBLSPACE=users"
      - "WLS_PW=weblogic1"
  links:
      - db:db.box
```

### Changing the database connection information to a running TSAM application
The Oracle Database connection is managed in the Oracle WebLogic domain, under the datasource named `tsamds`. The TSAM application itself does not hold any database connection specific information, instead refers to the database through a JNDI named `jdbc/tsamds`.

So, to make the TSAM application connect to another Oracle Database, login to the Oracle WebLogic admin console, which should be running at `http://<container_ip_address>:<wls_adm_svr_port>/console` (or `http://<host_ip_address>:<mapped_wls_adm_svr_port>/console`), then change the database connection information under the datasource `tsamds`, followed by a restart of the TSAM application named `tsam_wls12c`.

> Note that the targeting database instance should contain the whole TSAM schema of a matching version. If no valid database schema could be used, the TSAM application will fail to restart.

## License
To download and run Oracle TSAM Plus, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project required to build the Docker images are, unless otherwise noted, released under the Common Development and Distribution License (CDDL) 1.0 and GNU Public License 2.0 licenses.

## Copyright
Copyright (c) 1996-2017 Oracle and/or its affiliates. All rights reserved.
