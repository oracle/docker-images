#Coherence Clustering on Docker

Coherence is a distributed caching product which that means that multiple Coherence storage enabled members are run together to form a cluster. Typically this cluster is spread across multiple machines for resiliency so when using Docker a cluster would be run using multiple containers across multiple Docker hosts.


### 1. Clustering Using Host Networking
The easiest way to make Coherence work inside Docker containers is to run the containers with the `--net=host` argument. This allows the containers to use their host's network interfaces rather than using virtualized networks. When using host networking everything in Coherence will work as normal.

1. Set up the Docker environment as described in the [Setup](../0.setup) section.

2. Start the first `DefaultCacheServer` targeting the `coh-demo0` Docker Machine VM using this command:

    ```
    $ docker $(docker-machine config coh-demo0) run -d --net=host \
    --name=coh1 oracle/coherence:12.2.1.0.0-standalone \
    /usr/java/default/bin/java \
    -cp /u01/oracle/oracle_home/coherence/lib/coherence.jar \
    com.tangosol.net.DefaultCacheServer
    ```

    The command above will start the container running DefaultCacheServer using the default configuration files from the `coherence.jar` file.
    
    * The `$(docker-machine config coh-demo0)` argument targets the docker command at the `coh-demo0` machine.

    * The `--net=host` argument will make the container use host networking.

    * The container has been given the name `coh1` using the `--name=coh1` argument. The container name is irrelevant to the example but it makes it easier to identify the container later.

    * The Java command is run from the location where Java is installed in the Java 8 base image `/usr/java/default/bin/java`.

    * The class path is set to just the Coherence JAR file from the Coherence install which is located in `/u01/oracle/oracle_home/coherence/lib`.


3. To verify that the container is running properly the Docker logs command can be used:

    `$ docker $(docker-machine config coh-demo0) logs coh1`
    
    If the container is running a DefaultCacheServer correctly the end of the log should display the following:

    ```
    Services
      (
      ClusterService{Name=Cluster, State=(SERVICE_STARTED, STATE_JOINED), Id=0, OldestMemberId=1}
      TransportService{Name=TransportService, State=(SERVICE_STARTED), Id=1, OldestMemberId=1}
      InvocationService{Name=Management, State=(SERVICE_STARTED), Id=2, OldestMemberId=1}
      PartitionedCache{Name=PartitionedCache, State=(SERVICE_STARTED), LocalStorage=enabled, PartitionCount=257, BackupCount=1, AssignedPartitions=257, BackupPartitions=0, CoordinatorId=1}
      ProxyService{Name=Proxy, State=(SERVICE_STARTED), Id=4, OldestMemberId=1}
      )
    
    Started DefaultCacheServer...
    ```

4. Start the second `DefaultCacheServer` on the `coh-demo1` Docker Machine VM using this command:

    ```
    $ docker $(docker-machine config coh-demo1) run -d  --net=host \
    --name=coh2 oracle/coherence:12.2.1.0.0-standalone \
    /usr/java/default/bin/java \
    -cp /u01/oracle/oracle_home/coherence/lib/coherence.jar \
    com.tangosol.net.DefaultCacheServer
    ```

    This command is exactly the same as the previous command but uses Docker Machine to target the `coh-demo1` host and the container has been given the name `coh2` using the `--name=coh2` argument.

5. Again to verify that the container is running properly the Docker logs command can be used:

    `$ docker $(docker-machine config coh-demo1) logs coh2`
    
    If the container is running a DefaultCacheServer correctly the end of the log should display the same text as the first container:
    
    ```
    Services
      (
      ClusterService{Name=Cluster, State=(SERVICE_STARTED, STATE_JOINED), Id=0, OldestMemberId=1}
      TransportService{Name=TransportService, State=(SERVICE_STARTED), Id=1, OldestMemberId=1}
      InvocationService{Name=Management, State=(SERVICE_STARTED), Id=2, OldestMemberId=1}
      PartitionedCache{Name=PartitionedCache, State=(SERVICE_STARTED), LocalStorage=enabled, PartitionCount=257, BackupCount=1, AssignedPartitions=257, BackupPartitions=0, CoordinatorId=1}
      ProxyService{Name=Proxy, State=(SERVICE_STARTED), Id=4, OldestMemberId=1}
      )
    
    Started DefaultCacheServer...
    ```
    
    Scrolling a little higher up the log will show the cluster membership something like this:
    
    ```
    MasterMemberSet(
      ThisMember=Member(Id=2, Timestamp=2016-05-17 13:25:00.271, Address=10.0.1.3:41302, MachineId=44598, Location=machine:coh2,process:1, Role=CoherenceConsole)
      OldestMember=Member(Id=1, Timestamp=2016-05-17 12:32:51.103, Address=10.0.1.2:33592, MachineId=44597, Location=machine:coh1,process:1, Role=CoherenceServer)
      ActualMemberSet=MemberSet(Size=2
        Member(Id=1, Timestamp=2016-05-17 12:32:51.103, Address=10.0.1.2:33592, MachineId=44597, Location=machine:coh1,process:1, Role=CoherenceServer)
        Member(Id=2, Timestamp=2016-05-17 13:25:00.271, Address=10.0.1.3:41302, MachineId=44598, Location=machine:coh2,process:1, Role=CoherenceConsole)
        )
      MemberId|ServiceJoined|MemberState
        1|2016-05-17 12:32:51.103|JOINED,
        2|2016-05-17 13:25:00.271|JOINED
      RecycleMillis=1200000
      RecycleSet=MemberSet(Size=1
        Member(Id=4, Timestamp=2016-05-17 13:24:43.68, Address=10.0.1.3:35598, MachineId=44598)
        )
      )
    ```

    Which shows that the two containers have discovered each other and formed a cluster using Coherence's default multi-cast discovery mechanism.

6. The containers can be closed by executing the following commands:

    `$ docker $(docker-machine config coh-demo0) stop coh1`
    
    `$ docker $(docker-machine config coh-demo0) rm coh1`
    
    `$ docker $(docker-machine config coh-demo1) stop coh2`
    
    `$ docker $(docker-machine config coh-demo1) rm coh2`


### 2. Clustering Using Docker's Overlay Network
If host networking mode is not available then it is possible to make Coherence work using Docker's overlay network. Multicast is not properly supported by Docker's overlay network so it cannot be used by Coherence to form a cluster across multiple Docker hosts but a Coherence cluster can be started using well known addressing.
 
 Due to the limitations of Docker's network functionality prior to version 1.9 of Docker without using host network mode there was no way for Coherence members on Docker to form a cluster across multiple Docker hosts. Although there were (and still are) third party network add-ons for Docker, such as Weave, that allowed cross host networking.
 
 Coherence cluster membership by default works using multicast and even after Docker 1.9 multicast does not work across multiple Docker hosts. The overlay network interface reports that it does support multicast but multicast only appears to work on a single host, which is not sufficient as typical Coherence deployments are across multiple servers.
 
 A Coherence cluster can be run in Docker using well-known-addressing as shown in the following example. 

1. Set up the Docker environment as described in the [Setup](../0.setup) section as this example will use the `coh-net` overlay network created in the Setup section.

2. Running the following command to start a `DefaultCacheServer` on the first machine `coh-demo0`.

    ```
    $ docker $(docker-machine config coh-demo0) run -d \
    --name=coh1 --hostname=coh1 --net=coh-net \
    oracle/coherence:12.2.1.0.0-standalone \
    /usr/java/default/bin/java \
    -cp /u01/oracle/oracle_home/coherence/lib/coherence.jar \
    -Dcoherence.localhost=coh1 -Dcoherence.wka=coh1 \
    com.tangosol.net.DefaultCacheServer
    ```
    
    The command above will start the container running DefaultCacheServer using the default configuration files from the `coherence.jar` file.
    
    * The `$(docker-machine config coh-demo0)` argument targets the docker command at the `coh-demo0` machine.

    * The container has the name, and host name, set to `coh1` using the `--name=coh1 --hostname=coh1` arguments.

    * The container is attached to the `coh-net` overlay network that was created earlier using the `--net=coh-net` argument.

    * The Java command is run from the JAVA_HOME location that is installed in the Java 8 base image `/usr/java/default`.

    * The class path is set to just the Coherence JAR file from the Coherence install which is located in `/u01/oracle/oracle_home/coherence/lib`.

    * Coherence is configured to bind to the coh1 address using the `-Dcoherence.localhost=coh1` property. This is because the container will have two network interfaces, the default Docker bridge and the overlay network `coh-net`. Coherence must bind to the overlay network so that it can be visible to other containers. If it binds to the bridge network then it cannot form a cluster.

    * The default Coherence operational configuration file allows the system property `coherence.wka` to be used to specify a single WKA address, in this case the `-Dcoherence.wka=coh1` argument has set the WKA name to be the same host name that is used by the container. Typically in a real cluster a custom overrides file would be used to supply multiple addresses, ideally one address per host that Coherence will be run on. For Docker this is not going to work as each container is effectively a single host with a host name specified on start-up so when using Docker the WKA list can be a sub-set of the names of the containers (in the example above the host name used is `coh1` as this is the first container started).
 

3. To verify that the container is running properly the Docker logs command can be used:

    `$ docker $(docker-machine config coh-demo0) logs coh1`
    
    If the container is running a DefaultCacheServer correctly the end of the log should display the following:
    
    ```
    Services
      (
      ClusterService{Name=Cluster, State=(SERVICE_STARTED, STATE_JOINED), Id=0, OldestMemberId=1}
      TransportService{Name=TransportService, State=(SERVICE_STARTED), Id=1, OldestMemberId=1}
      InvocationService{Name=Management, State=(SERVICE_STARTED), Id=2, OldestMemberId=1}
      PartitionedCache{Name=PartitionedCache, State=(SERVICE_STARTED), LocalStorage=enabled, PartitionCount=257, BackupCount=1, AssignedPartitions=257, BackupPartitions=0, CoordinatorId=1}
      ProxyService{Name=Proxy, State=(SERVICE_STARTED), Id=4, OldestMemberId=1}
      )
    
    Started DefaultCacheServer...
    ```
    
    And to confirm WKA is working a little above the end of the log should be the following lines:
    
    ```
    WellKnownAddressList(
      10.0.1.2
      172.18.0.2
      )
    ```

    Coherence is using both of the container's IP addresses for its WKA list, most importantly it is using the 10.0.1.2 address, which is from the overlay network. When running the examples the IP addresses will vary depending on the addresses assigned to the containers by Docker.

4. A second DefaultCacheServer container can now be started on the other Docker Machine host in exactly the same way except that the container will need to have a different name and host name as these must be unique on the overlay network. The second container can be started with this command:

    ```
    $ docker $(docker-machine config coh-demo1) run -d \
    --name=coh2 --hostname=coh2 --net=coh-net \
    oracle/coherence:12.2.1.0.0-standalone \
    /usr/java/default/bin/java \
    -cp /u01/oracle/oracle_home/coherence/lib/coherence.jar \
    -Dcoherence.localhost=coh2 -Dcoherence.wka=coh1 \
    com.tangosol.net.DefaultCacheServer
    ```

    * The `$(docker-machine config coh-demo1)` argument targets the docker command at the `coh-demo1` machine.
    * The container has the name, and host name, set to `coh2` using the `--name=coh2 --hostname=coh2` arguments.
    * Coherence is configured to bind to the `coh2` address on the overlay network using the `-Dcoherence.localhost=coh2` property.
    * The rest of the command is identical to the first container, including setting the WKA to `coh1` which is the host name of the first container and which should be visible to the second container over the overlay network.

5. Again to verify that the container is running properly the Docker logs command can be used:
    
    `$ docker $(docker-machine config coh-demo1) logs coh2`
    
    If the container is running a DefaultCacheServer correctly the end of the log should display the same text as the first container:
    ```
    Services
      (
      ClusterService{Name=Cluster, State=(SERVICE_STARTED, STATE_JOINED), Id=0, OldestMemberId=1}
      TransportService{Name=TransportService, State=(SERVICE_STARTED), Id=1, OldestMemberId=1}
      InvocationService{Name=Management, State=(SERVICE_STARTED), Id=2, OldestMemberId=1}
      PartitionedCache{Name=PartitionedCache, State=(SERVICE_STARTED), LocalStorage=enabled, PartitionCount=257, BackupCount=1, AssignedPartitions=257, BackupPartitions=0, CoordinatorId=1}
      ProxyService{Name=Proxy, State=(SERVICE_STARTED), Id=4, OldestMemberId=1}
      )
    
    Started DefaultCacheServer...
    ```
    
    And the WKA list a little higher should display the overlay network IP address of the `coh1` host:
    
    ```
    WellKnownAddressList(
      10.0.1.2
      )
    ```
    
    It should also be obvious from the log that the two containers have formed a cluster by looking at the member set information:
    
    ```
    MasterMemberSet(
      ThisMember=Member(Id=2, Timestamp=2016-05-17 10:43:06.454, Address=10.0.1.3:33628, MachineId=44598, Location=machine:coh2,process:1, Role=CoherenceServer)
      OldestMember=Member(Id=1, Timestamp=2016-05-17 10:40:59.914, Address=10.0.1.2:46239, MachineId=44597, Location=machine:coh1,process:1, Role=CoherenceServer)
      ActualMemberSet=MemberSet(Size=2
        Member(Id=1, Timestamp=2016-05-17 10:40:59.914, Address=10.0.1.2:46239, MachineId=44597, Location=machine:coh1,process:1, Role=CoherenceServer)
        Member(Id=2, Timestamp=2016-05-17 10:43:06.454, Address=10.0.1.3:33628, MachineId=44598, Location=machine:coh2,process:1, Role=CoherenceServer)
        )
      MemberId|ServiceJoined|MemberState
        1|2016-05-17 10:40:59.914|JOINED,
        2|2016-05-17 10:43:06.454|JOINED
      RecycleMillis=1200000
      RecycleSet=MemberSet(Size=0
        )
      )
    ```

6. That was a simple demo showing that Coherence can form a cluster using WKA across multiple Docker hosts using an overlay network.
    
    The servers can be stopped and removed with these commands:
    
    `$ docker $(docker-machine config coh-demo0) stop coh1`
    
    `$ docker $(docker-machine config coh-demo0) rm coh1`
    
    `$ docker $(docker-machine config coh-demo1) stop coh2`
    
    `$ docker $(docker-machine config coh-demo1) rm coh2`

