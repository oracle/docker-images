#Coherence Clustering on Docker

Coherence is a distributed caching product which that means that multiple Coherence storage enabled members are run together to form a cluster. Typically this cluster is spread across multiple machines for resiliency.

Prior to version 1.9 of Docker and the limitations of how Docker's networking was implemented there was no way for Coherence members on Docker to form a cluster across multiple Docker hosts. There were (and still are) third party network add-ons for Docker, such as Weave, that allowed cross host networking but Coherence has to be usable with vanilla Docker so requires Docker version 1.9+.

Coherence cluster membership by default works using multicast and even after Docker 1.9 multicast does not work across multiple Docker hosts (even though the network reports that it does support multicast). Multicast does work on a single host but that is not sufficient as typical Coherence deployments are across multiple servers.

It is still possible to make Coherence members form a cluster in Docker by disabling multicast and using the well-known-address configuration.

##Example

### 1. Setup Docker
Running a multi-host Coherence cluster requires at least two Docker hosts configured with an overlay network. The easiest way to do this in an example is to use Docker Machine to build some temporary VMs that can then be disposed of at the end of the examples. A very similar configuration can be used to that in Docker's own [Get Started with multi-host networking](https://docs.docker.com/engine/userguide/networking/get-started-overlay/) examples using Consul as the keystore required to use Docker networking. This example is not going to use Swarm so there is no requirement to configure it.

1. Create the Consul key store machine

`$ docker-machine create -d virtualbox coh-keystore`

2. Set your local environment to the coh-keystore machine.

`$ eval "$(docker-machine env coh-keystore)"`

3. Start a `progrium/consul` container running on the coh-keystore machine.

`$ docker run -d -p "8500:8500" -h "consul" progrium/consul -server -bootstrap`

4. Create the two machines that will run the Coherence cluster.

```
docker-machine create -d virtualbox \
--engine-opt="cluster-store=consul://$(docker-machine ip coh-keystore):8500" \
--engine-opt="cluster-advertise=eth1:2376" \
coh-demo0
```

```
docker-machine create -d virtualbox \
--engine-opt="cluster-store=consul://$(docker-machine ip coh-keystore):8500" \
--engine-opt="cluster-advertise=eth1:2376" \
coh-demo1
```

5. Create an overlay network, this command only needs to be executed for one of the cluster machines.

```
$ docker $(docker-machine config coh-demo0) network create \
--driver overlay coh-net
```

6. Build the Java 8 image. Change directory to the `OracleJDK/java-8` directory, make sure the required JRE install has been downloaded to that directory and run these commands:

`$ eval "$(docker-machine env coh-demo0)"`

`$ sh build.sh`

`$ eval "$(docker-machine env coh-demo1)"`

`$ sh build.sh`

7. Build the Coherence image. Change directory to the OracleCoherence/dockerfiles/12.2.1 directory, make sure that the Coherence 12.2.1 Standalone installer has been downloaded to the directory and run these commands:

`$ eval "$(docker-machine env coh-demo0)"`

`$ sh buildDockerImage.sh -s`

`$ eval "$(docker-machine env coh-demo1)"`

`$ sh buildDockerImage.sh -s`

There should now be three Docker Machine VMs running, one running the Consul key store and two with the `oracle/coherence:12.2.1.0.0-standalone` image.

### 2. Running DefaultCacheServer
A container can be started running `com.tangosol.net.DefaultCacheServer` with well known addressing using the `oracle/coherence:12.2.1.0.0-standalone` image created above by running the following command.

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

To verify that the container is running properly the Docker logs command can be used:

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
Coherence is using both of the container's IP addresses for its WKA list, most importaintly it is using the 10.0.1.2 address, which is from the overlay network. The IP address will vary depending on the address assigned by Docker.

A second DefaultCacheServer container can now be started on the other Docker Machine host in exactly the same way except that the container will need to have a different name and host name as these must be unique on the overlay network. The second container can be started with this command:
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

Again to verify that the container is running properly the Docker logs command can be used:

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

That was a simple demo showing that Coherence can form a cluster using WKA across multiple Docker hosts using an overlay network.

The servers can be stopped and removed with these commands:

`$ docker $(docker-machine config coh-demo0) stop coh1`

`$ docker $(docker-machine config coh-demo0) rm coh1`

`$ docker $(docker-machine config coh-demo1) stop coh2`

`$ docker $(docker-machine config coh-demo1) rm coh2`


### Limitations
Due to the limitations of how Docker does networking this is obviously going mean that there are limitations on the functionality available for Coherence. In the example above the cluster was formed by using the overlay network. This network is only visible to containers and so it is not possible to mix cluster membership using containerized and non-containerized processes.

It is possible to use Docker's host network configuration by using the `--net=host` argument when running a container and this will make the containers use the host's network stack instead of Docker's virtualized networks. Host networking removes the limitations on Coherence imposed by Docker but at the cost of possibly making it harder to manage container port clashes etc. For Coherence port management from version 12.2.1 onwards is much easier as Coherence will use ephemeral ports so there are no ports to be configured so Coherence could run as easily with host networking as it does with the overlay network.

### Recap of the Important Points
Oracle Coherence will form a cluster across multiple hosts in Docker containers with the following configuration:

1. All of the containers in the cluster must be attached to the same overlay network.

2. Set the container name and host name to the same value.

2. Start the containers named in the WKA list first.

2. Configure the cluster to use well known addressing.

3. Set the `coherence.localhost` system property to the host name of the container.