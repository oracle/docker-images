# Oracle NoSQL Database on Docker

Sample Docker build files to facilitate installation and environment setup for
DevOps users. For more information about Oracle NoSQL Database please see the
[Oracle NoSQL Database documentation](https://docs.oracle.com/en/database/other-databases/nosql-database/index.html).

This project offers sample Dockerfiles for:

* [Oracle NoSQL Database (19.5) Community Edition](19.5/Dockerfile)
* [Oracle NoSQL Database (4.5.12) Enterprise Edition](4.5.12/Dockerfile)
* [Oracle NoSQL Database (4.4.6) Enterprise Edition](4.4.6/Dockerfile)
* [Oracle NoSQL Database (4.3.11) Community Edition](4.3.11/Dockerfile)
* [Oracle NoSQL Database (4.0.9) Community Edition](4.0.9/Dockerfile)
* [Oracle NoSQL Database (3.5.2) Community Edition](3.5.2/Dockerfile)
* [Oracle NoSQL Database (3.4.7) Community Edition](3.4.7/Dockerfile)

## Quick start: building the Oracle NoSQL Community Edition image

To build the Oracle NoSQL Community Edition container image, clone this
repository and run the following commands from the root of cloned repository:

```shell
cd NoSQL/19.5-ce/
docker build -t oracle/nosql:19.5-ce .
```

The resulting image will be available as `oracle/nosql:19.5-ce`. You can also
pull the image directly from the GitHub Container Registry:

```shell
docker pull ghcr.io/oracle/nosql:19.5-ce
docker tag ghcr.io/oracle/nosql:19.5-ce oracle/nosql:19.5-ce
```

## Quick start: running Oracle NoSQL Database in a container

The steps outlined below are using Oracle NoSQL Database community edition, if
you are using Oracle NoSQL Database Enterprise Edition, please use the
appropriate image name.

Start up KVLite in a Docker container. You must give it a name. Startup of
KVLite is the default `CMD` of the Docker image:

```shell
docker run -d --name=kvlite oracle/nosql:19.5-ce
```

In a second shell, run a second Docker container to ping the kvlite store
instance:

```shell
docker run --rm -ti --link kvlite:store oracle/nosql:19.5-ce \
  java -jar lib/kvstore.jar ping -host store -port 5000
```

Note the required use of `--link` for proper hostname check (actual KVLite
container is named `kvlite`; alias is `store`).

You can also use the Oracle NoSQL Command Line Interface (CLI). Start the
following container (keep container `kvlite` running):

```shell
$ docker run --rm -ti --link kvlite:store oracle/nosql:19.5-ce \
  java -jar lib/kvstore.jar runadmin -host store -port 5000 -store kvstore

  kv-> ping
  Pinging components of store kvstore based upon topology sequence #14
  10 partitions and 1 storage nodes
  Time: 2017-02-28 15:37:41 UTC   Version: 12.1.4.3.11
  Shard Status: healthy:1 writable-degraded:0 read-only:0 offline:0
  Admin Status: healthy
  Zone [name=KVLite id=zn1 type=PRIMARY allowArbiters=false]   RN Status: online:1 offline:0
  Storage Node [sn1] on 659dbf4fba07:5000
  Zone: [name=KVLite id=zn1 type=PRIMARY allowArbiters=false]
  Status: RUNNING  Ver: 12cR1.4.3.11 2017-02-17 06:52:09 UTC  Build id: 0e3ebe7568a0
  Admin [admin1]     Status: RUNNING,MASTER
  Rep Node [rg1-rn1] Status: RUNNING,MASTER sequenceNumber:49 haPort:5006

  kv-> put kv -key /SomeKey -value SomeValue
  Operation successful, record inserted.
  kv-> get kv -key /SomeKey
  SomeValue
  kv->
```

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

Copyright (c) 2017, 2020 Oracle and/or its affiliates.
