# Oracle NoSQL Database on Docker

Sample Docker build files to facilitate installation and environment setup for
DevOps users. For more information about Oracle NoSQL Database please see the
[Oracle NoSQL Database documentation][DOCS].

This project offers sample container image configuration files for:

* [Oracle NoSQL Database Community Edition](ce/Dockerfile)

This container image uses a simplified version of the Oracle NoSQL Database called
 KVLite. KVLite runs as a single process that provides a single storage node and
 single storage shard. KVLite does not include replication or administration.

> **Note:** KVLite is NOT intended for production deployment or performance
> measurements.  We recommend testing with data that is NOT considered sensitive
> in nature. In other words, do not test with sensitive information such as
> usernames, passwords, credit card information, medication information, etc.
>
> **Note:** There are 2 container images available, one using a secure configuration
> and one using a non-secure configuration.    The primary difference is in the way
> access is performed to KVLite.   We recommend using the secure setup, albeit
> additional steps are needed during set up.  One advantage to using the secure
> set up is it gives you exposure to what is needed to set up a secure KVStore.

## Quick start: pull the Oracle NoSQL Community Edition image

You can  pull the image directly from the GitHub Container Registry:

```shell
docker pull ghcr.io/oracle/nosql:latest-ce
docker tag ghcr.io/oracle/nosql:latest-ce oracle/nosql:ce
```

The resulting image will be available as `oracle/nosql:ce`.

## Quick start: running Oracle NoSQL Database in a container

The steps outlined below are using Oracle NoSQL Database Community Edition, if
you are using Oracle NoSQL Database Enterprise Edition, please use the
appropriate image name.

### Start up KVLite in a container

You must give it a name and provide a hostname. Startup of
KVLite is the default `CMD` of the image:

```shell
docker run -d --name=kvlite --hostname=kvlite --env KV_PROXY_PORT=8080 -p 8080:8080 oracle/nosql:ce
```

By default, the KVLite store created has a size of `10GB`. Use `--env KV_STORAGESIZE=N`
to set a new value where `N` is in gigabytes and must be greater than 1.

In a second shell, run a second container to ping the kvlite store
instance:

```shell
docker run --rm -ti --link kvlite:store oracle/nosql:ce \
  java -jar lib/kvstore.jar ping -host store -port 5000
```

Note the use of the `--link` parameter to ensure successful hostname resolution
between containers: the KVLite container's hostname is `kvlite` and this creates
an alias for it of `store` which is then used in the `ping` command.

### Oracle NoSQL Command Line Interface

You can use the same KVLite image to access the Oracle NoSQL command-line
interface.

For example, to check the version of KVLite, use the `version` command:

```shell
$ docker run --rm -ti --link kvlite:store oracle/nosql:ce  java -Xmx64m -Xms64m -jar lib/kvstore.jar version
24.3.9 2024-09-26 18:01:32 UTC  Build id: 0d82533c492e Edition: Community
```

To check the size of the storage shard:

```shell
$ docker run --rm -ti --link kvlite:store oracle/nosql:ce \
    java -jar lib/kvstore.jar runadmin -host store -port 5000 \
    -store kvstore show parameters -service sn1 | grep GB
path=/kvroot/kvstore/sn1 size=10 GB
```

For an interactive CLI session, use the `runadmin` command from a second
container and link it to the first one.

Here's an example of using the CLI to ping the first instance:

```shell
$ docker run --rm -ti --link kvlite:store oracle/nosql:ce \
  java -jar lib/kvstore.jar runadmin -host store -port 5000 -store kvstore

  kv-> ping
  
Pinging components of store kvstore based upon topology sequence #14
10 partitions and 1 storage nodes
Time: 2024-12-04 11:50:35 UTC   Version: 24.3.9
Shard Status: healthy: 1 writable-degraded: 0 read-only: 0 offline: 0 total: 1
Admin Status: healthy
Zone [name=KVLite id=zn1 type=PRIMARY allowArbiters=false masterAffinity=false]   RN Status: online: 1 read-only: 0 offline: 0
Storage Node [sn1] on kvlite: 5000    Zone: [name=KVLite id=zn1 type=PRIMARY allowArbiters=false masterAffinity=false]    Status: RUNNING   Ver: 24.3.9 2024-09-26 18:01:32 UTC  Build id: 0d82533c492e Edition: Community    isMasterBalanced: true     serviceStartTime: 2024-12-04 11:47:05 UTC
        Admin [admin1]          Status: RUNNING,MASTER  serviceStartTime: 2024-12-04 11:47:08 UTC       stateChangeTime: 2024-12-04 11:47:08 UTC        availableStorageSize: 2 GB
        Rep Node [rg1-rn1]      Status: RUNNING,MASTER sequenceNumber: 470 haPort: 5011 availableStorageSize: 9 GB storageType: HD      serviceStartTime: 2024-12-04 11:47:09 UTC       stateChangeTime: 2024-12-04 11:47:09 UTC
  
  kv-> put kv -key /SomeKey -value SomeValue
  Operation successful, record inserted.
  kv-> get kv -key /SomeKey
  SomeValue
  kv-> exit
```

And here's an example that lists the available tables:

```shell
$ docker run --rm -ti --link kvlite:store oracle/nosql:ce \
  java -jar lib/sql.jar -helper-hosts store:5000 -store kvstore

  sql-> show tables
  tables
    SYS$IndexStatsLease
    SYS$MRTableAgentStat
    SYS$MRTableInfo
    SYS$MRTableInitCheckpoint
    SYS$PartitionStatsLease
    SYS$SGAttributesTable
    SYS$StreamRequest
    SYS$StreamResponse
    SYS$TableMetadata
    SYS$TableStatsIndex
    SYS$TableStatsPartition
    SYS$TopologyHistory

  sql-> exit
```

## Oracle NoSQL Database Proxy

The Oracle NoSQL Database Proxy is a server that accepts requests from Oracle
NoSQL Database drivers and proxies them to one or more Oracle NoSQL Databases.
The Oracle NoSQL Database drivers can be used to access either the Oracle NoSQL
Database Cloud Service or an on-premise installation via the Oracle NoSQL Database
Proxy.

The Oracle NoSQL Database drivers are available for various programming languages.

Since the drivers and APIs are identical, applications can be moved between these
two options.

You can deploy a container-based Oracle NoSQL Database store first for a prototype
project, then move forward to Oracle NoSQL Database cluster for a production
project.

Here is a snippet showing the connection from a Node.js program.

```javascript
return new NoSQLClient({
  serviceType: ServiceType.KVSTORE,
  endpoint: 'nosql-container-host:8080'
});
```

## Advanced Scenario: connecting to Oracle NoSQL CE from another host

> We recommend using the Oracle NoSQL CLI via a local container-to-container
> connection as detailed above.

This scenario allows remote hosts to connects to an Oracle NoSQL CE instance
running inside a container. In this scenario, all the ports are
open, but when developing applications in this scenario, all connections should
be made via the Oracle NoSQL Database Proxy on the `KV_PROXY_PORT`.

First, install the latest version of Oracle NoSQL on your remote host:

```shell
KV_VERSION=24.3.9
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

Next, start up KVLite in a container, remembering to provide both a name and hostname.
For this instance, you need to publish the KVLite and Proxy ports:

* 5000: `KVPORT`
* 5010-5020: `KV_HA_RANGE`
* 5021-5049: `KV_SERVICE_RANGE`
* 8080: `KV_PROXY_PORT`

To ensure the hostname of your KVLite instance matches the hostname used by the
remote host, use the environment variable `$HOSTNAME` as the value for the `--hostname`
wen starting the container:

```shell
docker run -d --name=kvlite --hostname=$HOSTNAME \
  --env KV_PROXY_PORT=8080 \
  -p 8080:8080 \
  -p 5000:5000 \
  -p 5010-5020:5010-5020 \
  -p 5021-5049:5021-5049 \
  -p 5999:5999 \
  oracle/nosql:ce
```

By default, the KVLite store created has a size of `10GB`. Use `--env KV_STORAGESIZE=N`
to set a new value where `N` is in gigabytes and must be greater than 1.

In a second shell, run the NoSQL command to ping the KVLite `store`
instance:

```shell
java -jar $KVHOME/lib/kvstore.jar ping -host $HOSTNAME -port 5000
```

Note: the value provided for `-host` must match the hostname used when starting
the container.

Or use a container to run the NoSQL ping command:

```shell
docker run --rm -ti --link kvlite:store oracle/nosql:ce \
  java -jar lib/kvstore.jar ping -host store -port 5000
```

Note the use of `--link` for proper hostname resolution between containers as
the KVLite container is named `kvlite` and its alias is `store`.

To bypass the requirement to use `--link`, ensure the `name` and `hostname` of
the KVLite container are both set to the hostname of the host on which they are
running by using the `$HOSTNAME` environment variable for both. For example:

```shell
docker run -d --name=$HOSTNAME --hostname=$HOSTNAME
```

As all container names must be unique on a host, this restriction means only one
container instance can be directly remotely accessible.

You can use the admin Oracle NoSQL Command Line Interface (CLI) from the
host to access the container:

```shell
java -jar $KVHOME/lib/kvstore.jar runadmin -host $HOSTNAME -port 5000 -store kvstore
```

You can also use the Oracle NoSQL Shell Interface:

```shell
java -jar $KVHOME/lib/sql.jar -helper-hosts $HOSTNAME:5000 -store kvstore
```

## Advanced Scenario: connecting from a remote host using an alias

The hostname of your KVLite instance must be resolvable from the host itself
as well as all remote hosts. Preferably using DNS but adding entries to `/etc/hosts`
on all servers works for testing purposes.

```shell
$ cat /etc/hosts
10.0.0.143 nosql-container-host
10.0.0.143 kvlite-nosql-container-host
```

Ensure that the container host can resolve its own alias:

```shell
$ ping kvlite-nosql-container-host
PING kvlite-nosql-container-host (10.0.0.143) 56(84) bytes of data.
64 bytes from nosql-container-host (10.0.0.143): icmp_seq=1 ttl=64 time=0.259 ms
64 bytes from nosql-container-host (10.0.0.143): icmp_seq=2 ttl=64 time=0.241 ms
64 bytes from nosql-container-host (10.0.0.143): icmp_seq=3 ttl=64 time=0.192 ms
```

Start the KVLite container using the alias in the `--hostname` parameter:

```shell
docker run -d --name=kvlite \
    --hostname=kvlite-nosql-container-host \
    --env KV_PROXY_PORT=8080 \
    -p 8080:8080 \
    -p 5000:5000 \
    -p 5010-5020:5010-5020 \
    -p 5021-5049:5021-5049 \
    -p 5999:5999 \
    oracle/nosql:ce
```

You can now use the alias to connect to this container instance from the host:

```shell
java -jar $KVHOME/lib/kvstore.jar ping -host kvlite-nosql-container-host -port 5000
```

From another container using `--link`:

```shell
docker run --rm -ti --link kvlite:store oracle/nosql:ce \
    java -jar lib/kvstore.jar ping -host store -port 5000
```

Using the NoSQL Admin CLI:

```shell
java -jar $KVHOME/lib/kvstore.jar runadmin -host kvlite-nosql-container-host -port 5000 -store kvstore
```

Using the NoSQL Shell CLI:

```shell
java -jar $KVHOME/lib/sql.jar -helper-hosts kvlite-nosql-container-host:5000 -store kvstore
```

## Quick start: building the Oracle NoSQL Community Edition image

These examples assume you have cloned this repository and are inthe `NoSQL/ce`
directory.

To build a container image named `oracle/nosql-ce:latest` that has the latest
version of Oracle NoSQL CE:

```shell
docker build -t oracle/nosql-ce:latest .
```

To build a container that uses a specific version of Oracle NoSQL with the version
number used for the image tag:


```shell
KV_VERSION=24.3.9 docker build --build-arg "$KV_VERSION" --tag "oracle/nosql-ce:$KV_VERSION" .
```

## More information

For more information on [Oracle NoSQL][NOSQL] please review the
[Oracle NoSQL Database product documentation][DOCS].

## Licenses

Oracle NoSQL Community Edition is released under the [Apache 2.0 License][Apache-2.0].

The Oracle NoSQL Database Community Edition image image uses the GraalVM CE container image as its base image.
It is licensed under the [GNU General Public License v2.0 with Classpath Exception][GraalVM-License]

The files in this repository are licensed under the [Universal Permissive License 1.0](/LICENSE.txt)

## Support

Oracle provides no commercial support for the Oracle NoSQL Community Edition.

## Copyright

Copyright (c) 2017, 2024 Oracle and/or its affiliates.

[NOSQL]: http://www.oracle.com/technetwork/database/database-technologies/nosqldb/overview/index.html
[DOCS]: https://docs.oracle.com/en/database/other-databases/nosql-database/index.html
[Apache-2.0]: https://docs.oracle.com/en/database/other-databases/nosql-database/24.3/license/apache-license.html
[GraalVM-License]: https://github.com/graalvm/container/blob/master/LICENSE.md
