# Oracle Graph Server on Docker

This repository contains sample Docker build files to facilitate installation, configuration, and environment setup. For more information about Oracle Graph please see the [Documentation for Oracle Property Graph Release 21.4](https://docs.oracle.com/en/database/oracle/property-graph/21.4/books.html).

## Overview

Oracle Database is required for setting up Graph Server because the authentication mechanism of Oracle Database (based on database users) is used.

![](https://user-images.githubusercontent.com/4862919/138631261-105c0795-3942-483c-9e01-f28417bf6d59.png)

### Clone this repository

To setup the environment, clone this repository first. Here we use `~/oracle-graph` as a work directory.

    $ cd ~/
    $ mkdir oracle-graph
    $ cd oracle-graph
    $ git clone https://github.com/oracle/docker-images.git

Then, follow the two sections below.

- [Setup Database](#Setup_Database)
- [Setup Graph Server](#Setup_Graph_Server)

## Setup Database

In this section, we will setup a container for Oracle Database and another container for SQLcl, so we can try PGQL queries in the 2-tier deployment. For enabling Oracle Graph, we need to apply a **PL/SQL patch** to the database and add the **PGQL plugin** to SQLcl.

![](https://user-images.githubusercontent.com/4862919/139366077-8f63d92c-6192-4237-aa41-b4e20d117219.png)

If you have an **existing** environment running Oracle Database (>= 12.2), it can be configured for Oracle Graph and a new Graph Server container (in the next section) can also connect to it. Please skip the first step to create the database container, and proceed to the next step to configure the database.

### Create a database container

Oracle Database [Express Edition (XE)](https://www.oracle.com/database/technologies/appdev/xe.html) is freely available, and we can get the scripts to build Docker image for XE 18c from the official GitHub repository.

Build docker image. This step requires about 4GB memory.

    $ cd ~/oracle-graph/docker-images/OracleDatabase/SingleInstance/dockerfiles/18.4.0/
    $ docker build -t oracle/database:18.4.0-xe -f Dockerfile.xe .

Launch Oracle Database on a docker container.

    $ docker run --name database \
      -p 1521:1521 -e ORACLE_PWD=Welcome1 \
      -v $HOME:/host-home \
      oracle/database:18.4.0-xe

Once you got the message below, the database is ready.

    #########################
    DATABASE IS READY TO USE!
    #########################

Open another console and try connecting with SQL*Plus.

    $ docker exec -it database sqlplus sys/Welcome1@xepdb1 as sysdba

You will get this error when the database is not ready yet.

    ORA-12514: TNS:listener does not currently know of service requested in connect descriptor

You can stop and restart the container.

    $ docker stop database
    $ docker start database

To check the progress, see the logs.

    $ docker logs -f database

### Configure the database

You need to apply the PL/SQL patch to the database.

Go to the [Oracle Graph Server and Client](https://www.oracle.com/database/technologies/spatialandgraph/property-graph-features/graph-server-and-client/graph-server-and-client-downloads.html) page and download the PL/SQL package.

- oracle-graph-plsql-21.4.0.zip

Unzip the content under `oracle/oracle-graph-plsql/`.

    $ cd ~/oracle-graph/
    $ unzip oracle-graph-plsql-21.4.0.zip -d oracle-graph-plsql

Connect to the database container.

    $ docker exec -it database sqlplus sys/Welcome1@xepdb1 as sysdba

Enable the graph feature. Please note `$HOME` of the host is mounted to `/host-home` in the container.

    SQL> @/host-home/oracle-graph/oracle-graph-plsql/18c_and_below/opgremov.sql
    SQL> @/host-home/oracle-graph/oracle-graph-plsql/18c_and_below/catopg.sql
    SQL> exit

### Create a database user

Connect to the database container.

    $ docker exec -it database sqlplus sys/Welcome1@xepdb1 as sysdba

Create a database user `graphuser` and grant the necessary privileges.

    CREATE USER graphuser
    IDENTIFIED BY Welcome1
    DEFAULT TABLESPACE users
    TEMPORARY TABLESPACE temp
    QUOTA UNLIMITED ON users;

    GRANT
    alter session 
    , create procedure 
    , create sequence 
    , create session 
    , create table 
    , create trigger 
    , create type 
    , create view
    , graph_developer -- This role is required for using Graph Server
    TO graphuser;

Exit and confirm that you can connect as the user newly created.

    SQL> exit
    $ docker exec -it database sqlplus graphuser/Welcome1@xepdb1
    SQL> exit

### Setup a SQLcl container

You need SQLcl and its PGQL plugin to run PGQL queries. (SQL*Plus does not support PGQL.)

Download [PGQL Plugin for SQLcl](https://www.oracle.com/database/technologies/spatialandgraph/property-graph-features/graph-server-and-client/graph-server-and-client-downloads.html) and locate the file below into `21.4.0/` directory.

    ~/oracle-graph/docker-images/OracleGraphServer/
    ├─ 21.4.0/
        ├─ oracle-graph-sqlcl-plugin-21.4.0.zip

Go to the directory and build the image.

    $ cd ~/oracle-graph/docker-images/OracleGraphServer/21.4.0/
    $ docker build -t oracle/sqlcl-pgql:21.4.0 -f Dockerfile.sqlcl .

Create an alias and connect to the database with SQLcl.

    $ alias sql='docker run --rm -it oracle/sqlcl-pgql:21.4.0 sql'
    $ sql graphuser/Welcome1@host.docker.internal:1521/xepdb1
    SQL>

Check if you can enable the PGQL mode.

    SQL> pgql auto on
    PGQL Auto enabled for graph=[null], execute=[true], translate=[false]
    PGQL>

### Create a graph

Run the following PGQL queries using the PGQL mode of SQLcl.

Create a graph using the PG schema.

    CREATE PROPERTY GRAPH graph1;

Insert two vertices and an edge between them.

    INSERT INTO graph1 VERTEX v
    LABELS (PERSON) PROPERTIES (v.NAME = 'Alice');

    INSERT INTO graph1 VERTEX v
    LABELS (CAR) PROPERTIES (v.BRAND = 'Toyota');

    INSERT INTO graph1 EDGE e BETWEEN src AND dst
    LABELS (HAS) PROPERTIES (e.SINCE = 2017)
    FROM MATCH ( (src), (dst) ) ON graph1
    WHERE src.name = 'Alice' AND dst.brand = 'Toyota';

    COMMIT;

Query the car brand owned by Alice and since when.

    SELECT v1.NAME, LABEL(e), v2.BRAND, e.SINCE
    FROM MATCH (v1)-[e:HAS]->(v2) ON graph1
    WHERE v1.NAME = 'Alice';

Exit from SQLcl.

    PGQL> exit

## Setup Graph Server

In this section, we will additionally create a Graph Server container which also contains Graph Client and Graph Viz web application. Graph Server will be connected to the database above via JDBC, so the clients can login to the Graph Server using the database user authentication.

![](https://user-images.githubusercontent.com/4862919/139367239-63e03b8c-e503-4d5b-8a4f-4c0a68dc0d8d.png)

### Set the JDBC URL (optional)

If you use an existing database (= not the database container above), please open the configuration file below and set the JDBC URL accordingly.

    $ vi ~/oracle-graph/docker-images/OracleGraphServer/21.4.0/pgx.conf
    
    # Modify this line
    "jdbc_url": "jdbc:oracle:thin:@host.docker.internal:1521/xepdb1",

### Download packages

Download [Oracle Graph Server](https://www.oracle.com/database/technologies/spatialandgraph/property-graph-features/graph-server-and-client/graph-server-and-client-downloads.html) and [JDK 11 Linux x64 RPM Package](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html) (No cost for personal use and development use). Then, add the following files into `21.4.0/` directory.

    ~/oracle-graph/docker-images/OracleGraphServer/
    ├─ 21.4.0/
        ├─ oracle-graph-21.4.0.x86_64.rpm
        ├─ jdk-11.x.xx_linux-x64_bin.rpm

### Start Container

Go to the directory.

    $ cd ~/oracle-graph/docker-images/OracleGraphServer/21.4.0/

Build the image. `<version_of_JDK>` needs be replaced with the version, e.g. `11.0.10`.

    $ docker build . \
      --tag oracle/graph-server:21.4.0 \
      --build-arg VERSION_GSC=21.4.0 \
      --build-arg VERSION_JDK=<version_of_JDK>

Start a container. For Linux host, `--add-host=host.docker.internal:host-gateway` option should be added in order to map `host.docker.internal` to the gateway of the host.

    $ docker run \
      --name graph-server \
      --publish 7007:7007 \
      --volume $PWD/pgx.conf:/etc/oracle/graph/pgx.conf \
      oracle/graph-server:21.4.0

Open another console and confirm that you can connect to the container.

    $ docker exec -it graph-server /bin/bash
    # exit

You can stop and restart the container.

    $ docker stop graph-server
    $ docker start graph-server

### Login to Graph Viz

Access Graph Viz using a web browser. You will get warnings because it is using a self-signed cirtificate. For **Chrome**, type `thisisunsafe` to allows the access. For **Firefox**, click `Advanced` and `Accept the Risk and Continue` to proceed. 

- URL: https://localhost:7007/ui/
- Username: `graphuser`
- Password: `Welcome1`
- Advanced Options
  - `Database`
  - `jdbc:oracle:thin:@host.docker.internal:1521/xepdb1` (or an alternative JDBC URL)

![](https://user-images.githubusercontent.com/4862919/139385128-0f4cde78-9749-434e-8d03-deeeb7ee0e28.jpg)

Once logged in, pick `GRAPH1` and run the same query as in the previous section.

    SELECT v1.NAME, LABEL(e), v2.BRAND, e.SINCE
    FROM MATCH (v1)-[e:HAS]->(v2) ON graph1
    WHERE v1.NAME = 'Alice'

![](https://user-images.githubusercontent.com/4862919/139384916-138ccc94-8291-4950-8552-6d2a6408a107.jpg)