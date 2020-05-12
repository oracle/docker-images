Quickstart Running Oracle NoSQL Database on Docker

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
    Time: 2020-05-12 06:43:53 UTC   Version: 19.5.19
    Shard Status: healthy:1 writable-degraded:0 read-only:0 offline:0 total:1
    Admin Status: healthy
    Zone [name=KVLite id=zn1 type=PRIMARY allowArbiters=false masterAffinity=false]   RN Status: online:1 read-only:0 offline:0
    Storage Node [sn1] on 5463ba55a594:5000    Zone: [name=KVLite id=zn1 type=PRIMARY allowArbiters=false masterAffinity=false]    Status: RUNNING   Ver: 19.5.19 2020-01-27 07:15:29 UTC  Build id: 6783109c3c07 Edition: Community
	  Admin [admin1]		Status: RUNNING,MASTER
	  Rep Node [rg1-rn1]	Status: RUNNING,MASTER sequenceNumber:43 haPort:5003 available storage size:1023 MB
    
    kv-> put kv -key /SomeKey -value SomeValue
    Operation successful, record inserted.
    kv-> get kv -key /SomeKey
    SomeValue
    kv->
You have now Oracle NoSQL on a Docker container.

More information

For more information on Oracle NoSQL, visit the homepage and the documentation for specific NoSQL instructions.

The Oracle NoSQL Database Community Edition also contains OpenJDK. The Oracle NoSQL Database Enterprise Edition also contains Oracle Java Server JRE.

Licenses

Oracle NoSQL Community Edition is licensed under the APACHE LICENSE v2.0.

OpenJDK is licensed under the GNU General Public License v2.0 with the Classpath Exception

The files in this repository folder are licensed under the Universal Permissive License 1.0

Commercial Support on Docker Containers

Oracle NoSQL Community Edition has no commercial support.

Copyright

Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
