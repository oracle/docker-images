# Oracle NoSQL Database on Docker

Sample Docker build files to facilitate installation and environment setup for
DevOps users. For more information about Oracle NoSQL Database please see the
[Oracle NoSQL Database documentation](https://docs.oracle.com/en/database/other-databases/nosql-database/index.html).

This project offers sample container image configuration files for:

* [Oracle NoSQL Database Community Edition](ce/Dockerfile)

## Quick start: building the Oracle NoSQL Community Edition image

To build the Oracle NoSQL Community Edition container image, clone this
repository and run the following commands from the root of cloned repository:

```shell
cd NoSQL/ce/
docker build -t oracle/nosql .
```
or

```shell
cd NoSQL/ce/
docker build --build-arg KV_VERSION=20.3.19 --tag oracle/nosql:20.3 .
```

The resulting image will be available as `oracle/nosql:20.3-ce`. 

## Quick start: running Oracle NoSQL Database in a container

The steps outlined below are using Oracle NoSQL Database community edition, if
you are using Oracle NoSQL Database Enterprise Edition, please use the
appropriate image name.

Start up KVLite in a Docker container. You must give it a name. Startup of
KVLite is the default `CMD` of the image:

```shell
docker run -d --name=kvlite --env KV_PROXY_PORT=8080 -p 8080:8080 oracle/nosql:20.3
```

In a second shell, run a second container to ping the kvlite store
instance:

```shell
docker run --rm -ti --link kvlite:store oracle/nosql:20.3 \
  java -jar lib/kvstore.jar ping -host store -port 5000
```

Note the required use of `--link` for proper hostname check (actual KVLite
container is named `kvlite`; alias is `store`).

You can also use the Oracle NoSQL Command Line Interface (CLI). Start the
following container:

```shell

$ docker run --rm -ti --link kvlite:store oracle/nosql:20.3  java -Xmx64m -Xms64m -jar lib/kvstore.jar version

20.3.19 2021-09-29 04:04:01 UTC  Build id: b8acf274b357 Edition: Community

$ docker run --rm -ti --link kvlite:store oracle/nosql:20.3 \
  java -jar lib/kvstore.jar runadmin -host store -port 5000 -store kvstore

  kv-> ping
   Pinging components of store kvstore based upon topology sequence #14
   10 partitions and 1 storage nodes
   Time: 2021-12-20 12:56:33 UTC   Version: 20.3.19
   Shard Status: healthy:1 writable-degraded:0 read-only:0 offline:0 total:1
   Admin Status: healthy
   Zone [name=KVLite id=zn1 type=PRIMARY allowArbiters=false masterAffinity=false]   RN Status: online:1 read-only:0 offline:0
   Storage Node [sn1] on dcbd8ff4f07c:5000    Zone: [name=KVLite id=zn1 type=PRIMARY allowArbiters=false masterAffinity=false]    Status: RUNNING   Ver: 20.3.19 2021-09-29 04:04:01 UTC  Build id: b8acf274b357 Edition: Community
        Admin [admin1]          Status: RUNNING,MASTER
        Rep Node [rg1-rn1]      Status: RUNNING,MASTER sequenceNumber:50 haPort:5003 available storage size:1023 MB


  kv-> put kv -key /SomeKey -value SomeValue
  Operation successful, record inserted.
  kv-> get kv -key /SomeKey
  SomeValue
  kv-> exit
```

You can also use the Oracle SQL Shell Command Line Interface (CLI). Start the
following container:

```shell
$ docker run --rm -ti --link kvlite:store oracle/nosql:20.3 \
  java -jar lib/sql.jar -helper-hosts store:5000 -store kvstore

  sql-> show tables
  tables
    SYS$IndexStatsLease
    SYS$MRTableAgentStat
    SYS$MRTableInitCheckpoint
    SYS$PartitionStatsLease
    SYS$SGAttributesTable
    SYS$StreamRequest
    SYS$StreamResponse
    SYS$TableStatsIndex
    SYS$TableStatsPartition
  sql-> exit

```

## Oracle NoSQL Database Proxy

The Oracle NoSQL Database Proxy is a middle-tier component that lets the Oracle NoSQL Database drivers communicate with the Oracle NoSQL Database cluster. 
The Oracle NoSQL Database drivers are available in various programming languages that are used in the client application.

The Oracle NoSQL Database Proxy is a server that accepts requests from Oracle NoSQL Database drivers and processes them using the Oracle NoSQL Database. 
The Oracle NoSQL Database drivers can be used to access either the Oracle NoSQL Database Cloud Service or an on-premises installation via the Oracle NoSQL Database Proxy. 
Since the drivers and APIs are identical, applications can be moved between these two options. 

You can deploy a container-based Oracle NoSQL Database store first for a prototype project, and move forward to Oracle NoSQL Database cluster for a production project.

Here is a snippet showing the connection from a Node.js program.

````
return new NoSQLClient({
  serviceType: ServiceType.KVSTORE,
  endpoint: 'nosql-container-host:8080'
});
````

## More information

For more information on [Oracle NoSQL](http://www.oracle.com/technetwork/database/database-technologies/nosqldb/overview/index.html)
please review the [product documentation](http://docs.oracle.com/cd/NOSQL/html/index.html).

The Oracle NoSQL Database Community Edition image contains the OpenJDK.

## Licenses

Oracle NoSQL Community Edition is licensed under the [APACHE LICENSE v2.0](https://docs.oracle.com/cd/NOSQL/html/driver_table_c/doc/LICENSE.txt).

OpenJDK is licensed under the [GNU General Public License v2.0 with the Classpath Exception](http://openjdk.java.net/legal/gplv2+ce.html)

The files in this repository folder are licensed under the [Universal Permissive License 1.0](/LICENSE.txt)

## Commercial Support in Containers

Oracle NoSQL Community Edition has **no** commercial support.

## Copyright

Copyright (c) 2017, 2022 Oracle and/or its affiliates.
