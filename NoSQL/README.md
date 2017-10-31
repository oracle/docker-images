# Oracle NoSQL Database on Docker
Sample Docker build files to facilitate installation and environment setup for DevOps users. For more information about Oracle NoSQL Database please see the [Oracle NoSQL Database Online Documentation](http://docs.oracle.com/cd/NOSQL/html/).

This project offers sample Dockerfiles for:
 * Oracle NoSQL Database (4.5.12) Enterprise Edition 
 * Oracle NoSQL Database (4.4.6) Enterprise Edition 
 * Oracle NoSQL Database (4.3.11) Community Edition 
 * Oracle NoSQL Database (4.0.9) Community Edition 
 * Oracle NoSQL Database (3.5.2) Community Edition 
 * Oracle NoSQL Database (3.4.7) Community Edition 

# Quickstart Building docker images for Oracle NoSQL Database
For Enterprise Edition, download the bundle (in tar.gz format) from [Oracle Technology Network](http://www.oracle.com/technetwork/database/database-technologies/nosqldb/downloads/index.html) and copy it in the same directory as the Enterprise Edition Dockerfile. then build the docker image as per below,

        $ docker build -t oracle/nosqlee:4.5.12 .

For Community Edition, the zip bundle is already downloaded and available in the oracle/nosql:latest docker image. There is no need to build docker image for Community Edition.

# Quickstart Running Oracle NoSQL Database on Docker
The steps outlined below are using Oracle NoSQL Database community edition, if you are using Oracle NoSQL Database Enterprise Edition, please use the appropriate docker image name.

Start up KVLite in a Docker container. You must give it a name. Startup of KVLite is the default CMD of the Docker image:

        $ docker run -d --name=kvlite oracle/nosql

In a second shell, run a second Docker container to ping the kvlite store instance:

        $ docker run --rm -ti --link kvlite:store oracle/nosql \
          java -jar lib/kvstore.jar ping -host store -port 5000

Note the required use of --link for proper hostname check (actual KVLite container is named 'kvlite'; alias is 'store').

You can also use the Oracle NoSQL Command Line Interface (CLI). Start the following container (keep container 'kvlite' running):

        $ docker run --rm -ti --link kvlite:store oracle/nosql \
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
	Status: RUNNING   Ver: 12cR1.4.3.11 2017-02-17 06:52:09 UTC  Build id: 0e3ebe7568a0
	Admin [admin1]		Status: RUNNING,MASTER
	Rep Node [rg1-rn1]	Status: RUNNING,MASTER sequenceNumber:49 haPort:5006
        
        kv-> put kv -key /SomeKey -value SomeValue
        Operation successful, record inserted.
        kv-> get kv -key /SomeKey
        SomeValue
        kv->

You have now Oracle NoSQL on a Docker container.

# More information
For more information on Oracle NoSQL, visit the [homepage](http://www.oracle.com/technetwork/database/database-technologies/nosqldb/overview/index.html) and the [documentation](http://docs.oracle.com/cd/NOSQL/html/index.html) for specific NoSQL instructions.

The Oracle NoSQL Database Community Edition also contains OpenJDK.
The Oracle NoSQL Database Enterprise Edition also contains Oracle Java Server JRE.

# Licenses
Oracle NoSQL Community Edition is licensed under the [APACHE LICENSE v2.0](https://docs.oracle.com/cd/NOSQL/html/driver_table_c/doc/LICENSE.txt).

OpenJDK is licensed under the [GNU General Public License v2.0 with the Classpath Exception](http://openjdk.java.net/legal/gplv2+ce.html)

The files in this repository folder are licensed under the [Universal Permissive License 1.0](http://oss.oracle.com/licenses/upl)

# Commercial Support on Docker Containers
Oracle NoSQL Enterprise Edition is **not** certified on Docker.

Oracle NoSQL Community Edition has **no** commercial support.

# Copyright
Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
