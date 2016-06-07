#Using Coherence*Extend in Docker

## Using Host Networking
Coherence*Extend clients can be used with Docker and, as with clustering, the easiest way to make Extend work is to start the containers with `--net=host` to use host networking. When using host networking, the container uses the Docker host's network interfaces instead of virtualized interfaces, so all of the features of Coherence*Extend will work as normal.

## Using Overlay Networks
If host networking is not available, then Extend will also work using Docker's overlay and bridge networks. There are different configuration choices available depending on whether the Coherence cluster and Extend client are both running in containers or whether one is containerized and the other is not.   

##Examples

##Cluster and Client Both Containerized
If both the cluster members and the Extend client are inside Docker containers and attached to the same overlay network, then everything works as normal. The client and proxy services in the cluster can communicate using the overlay network. 

1. In Coherence 12.2.1, using the default cache configuration in the JAR file of every storage member also starts a proxy that listens on an ephemeral port. Start `DefaultCacheServer` on the `coh-demo0` machine using the following command:

```
$ docker $(docker-machine config coh-demo0) run -d \
--name=coh1 --hostname=coh1 --net=coh-net \
oracle/coherence:12.2.1.0.0-standalone \
/usr/java/default/bin/java \
-cp /u01/oracle/oracle_home/coherence/lib/coherence.jar \
-Dcoherence.localhost=coh1 -Dcoherence.wka=coh1 \
com.tangosol.net.DefaultCacheServer
```

2. The client used in this example is the CacheFactory console application. The default cache configuration file in 12.2.1 allows a JVM to be configured as a cluster member or an Extend client by setting the `coherence.client` system property. There are two valid values for this property `direct` for cluster members and `remote` for Extend clients. As of Coherence 12.2.1, Extend clients can locate a proxy without having to know any of the ports that the proxies are listening on. The client only needs to locate the cluster and then using the `NameService` service in the cluster it can look-up the proxy service. When using overlay networks, cluster discovery uses well-known-addressing so the Extend client must also be configured with the WKA list of the cluster. A client can be started with the following command:

```
$ docker $(docker-machine config coh-demo1) run -i -t \
--name=coh2 --hostname=coh2 --net=coh-net \
oracle/coherence:12.2.1.0.0-standalone \
/usr/java/default/bin/java \
-cp /u01/oracle/oracle_home/coherence/lib/coherence.jar \
-Dcoherence.client=remote -Dcoherence.wka=coh1 \
com.tangosol.net.CacheFactory
```

* The container starts in interactive mode so that commands can be typed into the console.
* The container is given a unique name and host name on the overlay network using the `--name=coh2 --hostname=coh2` arguments.
* The container is attached to the same overlay network as the storage member using the `--net=coh-net` argument.
* The container is configured to act as a client using the `-Dcoherence.client=remote` system property
* The WKA property `-Dcoherence.wka=coh1` is set so that the client can locate the cluster.


3. After the above command is run, the `CacheFactory` console should start and display the `Map (?): ` prompt. Create a cache in the console using the following command:

```
Map (?): cache foo
```
This command causes the client to connect to the Extend proxy and create a cache called `foo`, if everything works, then the command prompt changes to `Map (foo):`.

4. Information about the cache service for the cache that was just created can be displayed using the service command:

```
Map (foo): service
```
Which displays output similar to the following:
```
Map (foo): service
SafeCacheService: RemoteCacheService(Name=RemoteCache)
[Member(Id=2, Timestamp=2016-05-17 13:25:00.271, Address=10.0.1.3:41302, MachineId=44598, Location=machine:coh2,process:1, Role=CoherenceConsole)]

Map (foo):
```
The service type is a `RemoteCacheService` so the containerized client has connected to a proxy in exactly the same way that Coherence would work if it was not running inside containers.

##Containerized Extend Client with Non-Containerized Cluster
An Extend client application that is running inside a Docker container can easily connect to a cluster that is not running inside Docker. Many of the limitations imposed by Docker are only really relevant if connecting from the outside world into a container. To go the other way and connect from a container works as normal.

##Containerized Cluster with External Client
When connecting a non-containerized client to a containerized cluster, the configuration above will not work, again due to limitation of the way that Docker virtualizes the containers network and the use of NAT'ing to expose the container to the outside world.

In the above example, Coherence uses the default configuration for the Proxy and the client. The proxy listens on an ephemeral port and the client locates this port using the `NameService` service after locating the cluster. When using Docker, Coherence cannot be configured to use ephemeral ports due to the limitation of having to specify which ports a container will expose at the point when the container is started; this means that the proxy must be configured to listen on a specific port. The reason Coherence uses ephemeral ports is that it makes Coherence much easier to use as there will not be issues with port clashes due to multiple proxies being configured with the same port. When running in Docker, all of the proxies can be configured to use the same port because each container is isolated from the others so there is no contention for ports.

To be accessible from outside of the container, a proxy needs to be configured to listen on a specific port as in the example below:
```
    <proxy-scheme>
      <service-name>Proxy</service-name>
      <acceptor-config>
        <tcp-acceptor>
          <local-address>
            <address>0.0.0.0</address>
            <port>20000</port>
          </local-address>
        </tcp-acceptor>
      </acceptor-config>
      <load-balancer>client</load-balancer>
      <autostart>true</autostart>
    </proxy-scheme>
```
In the above configuration, the proxy listens on port 20000 on any local address.

Another limitation imposed by the use of NAT'ing by Docker is that Coherence load balancer must be set to `client` as in the example above. This is because Coherence does not know that it is running inside a container and assumes that the Proxy is listening on the internal IP addresses of the container. The Coherence load balancer sends an internal IP address back to the client, but the client cannot connect to these addresses; the client must use the NAT'ed addresses. By setting the load balancer to `client`, the server will not try to load balance clients to another proxy.

Extend clients must be configured with a specific set of proxy addresses to connect to when connecting to a containerized cluster. `The NameService` service cannot be used because it is part of the cluster and does not know about the external NAT'ed addresses and ports. The client must be configured using either an `AddressProvider` implementation or a fixed set of addresses. For example:
```
    <remote-cache-scheme>
      <scheme-name>remote-scheme</scheme-name>
      <service-name>RemoteCache</service-name>
      <proxy-service-name>Proxy</proxy-service-name>
      <initiator-config>
        <tcp-initiator>
          <remote-addresses>
            <socket-address>
              <address>192.168.0.10</address>
              <port>32001</port>
            </socket-address>
            <socket-address>
              <address>192.168.0.11</address>
              <port>32020</port>
            </socket-address>
          </remote-addresses>
        </tcp-initiator>
      </initiator-config>
    </remote-cache-scheme>
```
where 192.168.0.10 and 192.168.0.11 would be the Docker host machine IP addresses and 32001 and 32020 would be the ports on those machines that Docker has NAT'ed to the container's extend port.

Alternatively, a custom `AddressProvider` implementation can be used. This is especially usesful the Docker infrastructure has a facility to provide service discovery that allows applications to discover the port mappings for a containerized service. For example, if there was a class called `com.example.DockerAddressProvider` that looked up services using a remote discovery mechanism, then the client can configured as follows:
```
    <remote-cache-scheme>
      <scheme-name>remote-scheme</scheme-name>
      <service-name>RemoteCache</service-name>
      <proxy-service-name>Proxy</proxy-service-name>
      <initiator-config>
        <tcp-initiator>
          <remote-addresses>
            <address-provider>
              <instance>
                <class-name>com.example.DockerAddressProvider</class-name>
              </instance>
            </address-provider>
          </remote-addresses>
        </tcp-initiator>
      </initiator-config>
    </remote-cache-scheme>
```

## Host Networking
It is possible to use Docker's host network configuration by using the `--net=host` argument when running the container and this will make the containers use the host's network stack instead of Docker's virtualized networks. Host networking removes the limitations on Coherence imposed by Docker but at the cost of possibly making it harder to manage container port clashes. For Coherence port management from version 12.2.1 onwards, it is much easier as Coherence uses ephemeral ports so there are no ports to be configured and Coherence can run as easily with host networking as it does with the overlay network. When using host networking, all Coherence *Extend features work as normal.

### Recap of the Important Points
Oracle Coherence Extend clients work providing the following points are noted:

* If both client and proxy are containerized and attached to the same overlay network, then all Coherence*Extend features work.

* If the client is containerized and the proxy is not running in a container, then all Coherence*Extend features work.

* If connecting a non-containerized client to a containerized proxy, then the `<load-balancer>client<load-balancer>` setting must be used in the proxy configuration.

* If connecting a non-containerized client to a containerized proxy, then the `NameService` service cannot be used by the client to lookup Extend proxies. Proxy addresses must be explicitly set either in the client configuration or by using an `AddressProvider` implementation.
