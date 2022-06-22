# Oracle NoSQL Database on Docker

Sample Docker build files to facilitate installation and environment setup for
DevOps users. For more information about Oracle NoSQL Database please see the
[Oracle NoSQL Database documentation](https://docs.oracle.com/en/database/other-databases/nosql-database/index.html).

This project offers sample container image configuration files for:

* [Oracle NoSQL Database Community Edition](ce/Dockerfile)

This container image uses a simplified version of the Oracle NoSQL Database called KVLite. KVLite runs as a single process that provides a single storage node and single storage shard. KVLite does not include replication or administration. 

> **Note:** KVLite is not intended for production deployment or performance measurements.

## Quick start: pull the Oracle NoSQL Community Edition image

You can  pull the image directly from the GitHub Container Registry:

```shell
docker pull ghcr.io/oracle/nosql:latest-ce
docker tag ghcr.io/oracle/nosql:latest-ce oracle/nosql:ce
```

The resulting image will be available as `oracle/nosql:ce`. 

## Quick start: running Oracle NoSQL Database in a container

The steps outlined below are using Oracle NoSQL Database community edition, if
you are using Oracle NoSQL Database Enterprise Edition, please use the
appropriate image name.

Start up KVLite in a container. You must give it a name and provide a hostname. Startup of
KVLite is the default `CMD` of the image:

```shell
docker run -d --name=kvlite --hostname=kvlite --env KV_PROXY_PORT=8080 -p 8080:8080 oracle/nosql:ce
```
**Note**:  By default, the KVLite store created has a size of `10GB`, use `--env KV_STORAGESIZE=N` to override that. 
The value of `N` is in gigabytes and must be greater than 1GB.

In a second shell, run a second container to ping the kvlite store
instance:

```shell
docker run --rm -ti --link kvlite:store oracle/nosql:ce \
  java -jar lib/kvstore.jar ping -host store -port 5000
```

Note the required use of `--link` for proper hostname check (actual KVLite
container is named `kvlite`; alias is `store`).

You can also use the Oracle NoSQL Command Line Interface (CLI). Start the
following container:

```shell

$ docker run --rm -ti --link kvlite:store oracle/nosql:ce  java -Xmx64m -Xms64m -jar lib/kvstore.jar version

21.2.46 2022-05-24 20:36:59 UTC  Build id: 1b73ce65d872 Edition: Community

$ docker run --rm -ti --link kvlite:store oracle/nosql:ce   java -jar lib/kvstore.jar runadmin -host store -port 5000 \
-store kvstore show parameters -service sn1 | grep GB
    path=/kvroot/kvstore/sn1 size=10 GB


$ docker run --rm -ti --link kvlite:store oracle/nosql:ce \
  java -jar lib/kvstore.jar runadmin -host store -port 5000 -store kvstore

  kv-> ping
Pinging components of store kvstore based upon topology sequence #14
10 partitions and 1 storage nodes
Time: 2022-06-16 20:06:03 UTC   Version: 21.2.46
Shard Status: healthy: 1 writable-degraded: 0 read-only: 0 offline: 0 total: 1
Admin Status: healthy
Zone [name=KVLite id=zn1 type=PRIMARY allowArbiters=false masterAffinity=false]   RN Status: online: 1 read-only: 0 offline: 0
Storage Node [sn1] on kvlite: 5000    Zone: [name=KVLite id=zn1 type=PRIMARY allowArbiters=false masterAffinity=false]    Status: RUNNING   Ver: 21.2.46 2022-05-24 
20:36:59 UTC  Build id: 1b73ce65d872 Edition: Community    isMasterBalanced: true   serviceStartTime: 2022-06-16 19:56:24 UTC
        Admin [admin1]          Status: RUNNING,MASTER  serviceStartTime: 2022-06-16 19:56:27 UTC       stateChangeTime: 2022-06-16 19:56:26 UTC
        Rep Node [rg1-rn1]      Status: RUNNING,MASTER sequenceNumber: 293 haPort: 5011 availableStorageSize: 9 GB storageType: HD      serviceStartTime: 
 2022-06-16 19:56:28 UTC       stateChangeTime: 2022-06-16 19:56:29 UTC



  kv-> put kv -key /SomeKey -value SomeValue
  Operation successful, record inserted.
  kv-> get kv -key /SomeKey
  SomeValue
  kv-> exit
```

You can also use the Oracle SQL Shell Command Line Interface (CLI). Start the
following container:

```shell
$ docker run --rm -ti --link kvlite:store oracle/nosql:ce \
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
The Oracle NoSQL Database drivers can be used to access either the Oracle NoSQL Database Cloud Service or an on-premises installation via the Oracle NoSQL Database 
Proxy. 
Since the drivers and APIs are identical, applications can be moved between these two options. 

You can deploy a container-based Oracle NoSQL Database store first for a prototype project, and move forward to Oracle NoSQL Database cluster for a production 
project.

Here is a snippet showing the connection from a Node.js program.

````
return new NoSQLClient({
  serviceType: ServiceType.KVSTORE,
  endpoint: 'nosql-container-host:8080'
});
````

## Advanced Scenario: Using Oracle NoSQL Command-Line from an external host

**Note**: We recommend running NoSQL Command-Line and creating a container-to-container connection as detailed above.. 

It allows you to start a container with only the `KV_PROXY_PORT` enabled. 

For your developments, remember the SDK drivers will contact the Oracle NoSQL Database Proxy on KV_PROXY_PORT. 

If you need to run NoSQL Command-Line from a host outside any container, please follow those instructions.

Install Oracle NoSQL in your external host

```shell
KV_VERSION=21.2.46
rm -rf kv-$KV_VERSION
DOWNLOAD_ROOT=http://download.oracle.com/otn-pub/otn_software/nosql-database
DOWNLOAD_FILE="kv-ce-${KV_VERSION}.zip"
DOWNLOAD_LINK="${DOWNLOAD_ROOT}/${DOWNLOAD_FILE}"
curl -OLs $DOWNLOAD_LINK
jar tf $DOWNLOAD_FILE | grep "kv-$KV_VERSION/lib" > extract.libs
jar xf $DOWNLOAD_FILE @extract.libs 
rm -f $DOWNLOAD_FILE extract.libs
KVHOME=$PWD/kv-$KV_VERSION
```

Start up KVLite in a container. You must give it a name and provide a hostname. 
In this case, You need to publish all internal ports and the `KV_PROXY_PORT`:

- 5000 `KVPORT`
- 5010-5020 `KV_HA_RANGE` 
- 5021-5049 `KV_SERVICE_RANGE`
- 8080 `KV_PROXY_PORT`

Startup of KVLite is the default `CMD` of the image:

Use the environment variable `$HOSTNAME` as the value for the `--hostname`

```shell
docker run -d --name=kvlite --hostname=$HOSTNAME --env KV_PROXY_PORT=8080 -p 8080:8080 \
-p 5000:5000 -p 5010-5020:5010-5020 -p 5021-5049:5021-5049 -p 5999:5999 oracle/nosql:ce
```

**Note**:  By default, the KVLite store created has a size of `10GB`, use `--env KV_STORAGESIZE=N` to override that. 
The value of `N` is in gigabytes and must be greater than 1GB.

In a second shell, run the NoSQL command to ping the kvlite store
instance:

```shell
java -jar $KVHOME/lib/kvstore.jar ping -host $HOSTNAME -port 5000
```
Note: the value provided for `-host` must match the name used when starting the container.

If you want to run the NoSQL command to ping the kvlite store from another container:

```shell
docker run --rm -ti --link kvlite:store oracle/nosql:ce \
  java -jar lib/kvstore.jar ping -host store -port 5000
```
Note the required use of `--link` for proper hostname check (actual KVLite container is named `kvlite` and its alias is `store`).

If you want to run without `--link`, you can not use any alias when starting the container, so use `$HOSTNAME` instead..  

You can also use the admin Oracle NoSQL Command Line Interface (CLI).

```shell
$ java -jar $KVHOME/lib/kvstore.jar runadmin -host $HOSTNAME -port 5000 -store kvstore
````

You can also use the Oracle SQL Shell Command Line Interface (CLI)

```shell
$ java -jar $KVHOME/lib/sql.jar -helper-hosts $HOSTNAME:5000 -store kvstore
````

## Advanced Scenario: Using Oracle NoSQL Command-Line from an external host using an alias

**Note**: We recommend running NoSQL Command-Line doing a container to container connection as shown in the previous chapters. 
It allows starting the container without publishing all internal ports (KVPORT, KV_HARANGE, KV_SERVICERANGE) but only the KV_PROXY_PORT. 

For your developments, remember the SDK drivers will contact the Oracle NoSQL Database Proxy on KV_PROXY_PORT. 

If you need to run NoSQL Command-Line from a host outside any container, please follow those instructions.

Install Oracle NoSQL in your external host

```shell
KV_VERSION=21.2.46
rm -rf kv-$KV_VERSION
DOWNLOAD_ROOT=http://download.oracle.com/otn-pub/otn_software/nosql-database
DOWNLOAD_FILE="kv-ce-${KV_VERSION}.zip"
DOWNLOAD_LINK="${DOWNLOAD_ROOT}/${DOWNLOAD_FILE}"
curl -OLs $DOWNLOAD_LINK
jar tf $DOWNLOAD_FILE | grep "kv-$KV_VERSION/lib" > extract.libs
jar xf $DOWNLOAD_FILE @extract.libs 
rm -f $DOWNLOAD_FILE extract.libs
KVHOME=$PWD/kv-$KV_VERSION
```

Start up KVLite in a container. You must give it a name and provide a hostname. 
In this case, You need to publish all internal ports and the KV_PROXY_PORT.
- 5000 KVPORT
- 5010-5020 KV_HARANGE
- 5021-5049 KV_SERVICERANGE
- 8080 KV_PROXY_PORT

Startup of KVLite is the default `CMD` of the image:

This hostname must be resolvable from the host outside the container. It could be an alias to the host running the docker commands.

```shell
$ cat /etc/hosts
10.0.0.143 nosql-container-host
10.0.0.143 kvlite-nosql-container-host
```

```shell
$ ping kvlite-nosql-container-host

PING kvlite-nosql-container-host (10.0.0.143) 56(84) bytes of data.
64 bytes from nosql-container-host (10.0.0.143): icmp_seq=1 ttl=64 time=0.259 ms
64 bytes from nosql-container-host (10.0.0.143): icmp_seq=2 ttl=64 time=0.241 ms
64 bytes from nosql-container-host (10.0.0.143): icmp_seq=3 ttl=64 time=0.192 ms
```

```shell
docker run -d --name=kvlite --hostname=kvlite-nosql-container-host --env KV_PROXY_PORT=8080 -p 8080:8080 \
-p 5000:5000 -p 5010-5020:5010-5020 -p 5021-5049:5021-5049 -p 5999:5999 oracle/nosql:ce
```
**Note**:  By default, the KVLite store created has a size of `10GB`, use `--env KV_STORAGESIZE=N` to override that. 
The value of `N` is in gigabytes and must be greater than 1GB.

```shell
java -jar $KVHOME/lib/kvstore.jar ping -host kvlite-nosql-container-host -port 5000
```
Note: `-host` must be the same name used when starting the container

If you want to run the NoSQL command to ping the kvlite store from another container:

```shell
docker run --rm -ti --link kvlite:store oracle/nosql:ce \
  java -jar lib/kvstore.jar ping -host store -port 5000
```
Note the required use of --link for proper hostname check (actual KVLite container is named kvlite; alias is store).

If you want to run without --link, you cannot use any alias when starting the container (use HOSTNAME).  

You can also use the admin Oracle NoSQL Command Line Interface (CLI).

```shell
java -jar $KVHOME/lib/kvstore.jar runadmin -host kvlite-nosql-container-host -port 5000 -store kvstore
````

You can also use the Oracle SQL Shell Command Line Interface (CLI)

```shell
java -jar $KVHOME/lib/sql.jar -helper-hosts kvlite-nosql-container-host:5000 -store kvstore
````


## Quick start: building the Oracle NoSQL Community Edition image

To build the Oracle NoSQL Community Edition container image, clone this
repository and run the following commands from the root of cloned repository:

```shell
cd NoSQL/ce/
docker build -t oracle/nosql:ce .
```
or

```shell
cd NoSQL/ce/
docker build --build-arg KV_VERSION=21.2.46 --tag oracle/nosql:ce .
```

The resulting image will be available as `oracle/nosql:ce`. 


## More information

For more information on [Oracle NoSQL](http://www.oracle.com/technetwork/database/database-technologies/nosqldb/overview/index.html)
please review the [Oracle NoSQL Database product documentation](https://docs.oracle.com/en/database/other-databases/nosql-database/index.html).

The Oracle NoSQL Database Community Edition image contains the OpenJDK.

## Licenses

Oracle NoSQL Community Edition is released under the [Apache 2.0 License](https://docs.oracle.com/en/database/other-databases/nosql-database/22.1/license/index.html#NSXLI-GUID-006E432E-1965-45A2-AEDE-204BD05E1560) . 


OpenJDK is licensed under the [GNU General Public License v2.0 with the Classpath Exception](http://openjdk.java.net/legal/gplv2+ce.html)

The files in this repository folder are licensed under the [Universal Permissive License 1.0](/LICENSE.txt)

## Commercial Support in Containers

Oracle NoSQL Community Edition has **no** commercial support.

## Copyright

Copyright (c) 2017, 2022 Oracle and/or its affiliates.
