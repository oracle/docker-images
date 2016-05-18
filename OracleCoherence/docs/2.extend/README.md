#Using Coherence *Extend in Docker

Coherence *Extend clients can be used with Docker, the exact configuration depends on whether the cluster or client is inside or outside of a Docker container.

##Examples
The examples in this section follow on from those in the [Clustering Section](../1.clustering). To run the examples below the three Docker Machine VMs should have been created as previously explained along with the Consul key store container, image creation and network creation steps.

##Cluster and Client Both Containerized
If both the cluster members and the Extend client are inside Docker containers all attached to the same network then everything will work as normal.

1. Start a DefaultCacheServer on the coh-demo0 machine using the same command as previously:

```
$ docker $(docker-machine config coh-demo0) run -d \
--name=coh1 --hostname=coh1 --net=coh-net \
oracle/coherence:12.2.1.0.0-standalone \
/usr/java/default/bin/java \
-cp /u01/oracle/oracle_home/coherence/lib/coherence.jar \
-Dcoherence.localhost=coh1 -Dcoherence.wka=coh1 \
com.tangosol.net.DefaultCacheServer
```
In Coherence 12.2.1 using the default cache configuration in the JAR file every storage member will also start a Proxy that listens on an ephemeral port. An Extend client can be run in another container that will connect to the Proxy.

2. The client used in this example will be the CacheFactory console application. The default cache configuration file in 12.2.1 allows a JVM to be configured as a cluster member or an Extend client by setting the `coherence.client` system property. There are two valid values for this property `direct` for cluster members and `remote` for Extend clients. As of Coherence 12.2.1 Extend clients can locate a Proxy to connect to without requiring to know any of the ports that the proxies are listening on. The client only needs to locate the cluster and then using the NameService in the cluster it can look-up the  The client can be started with the following command:
```
$ docker $(docker-machine config coh-demo1) run -i -t \
--name=coh2 --hostname=coh2 --net=coh-net \
oracle/coherence:12.2.1.0.0-standalone \
/usr/java/default/bin/java \
-cp /u01/oracle/oracle_home/coherence/lib/coherence.jar \
-Dcoherence.client=remote -Dcoherence.wka=coh1 \
com.tangosol.net.CacheFactory
```
* The container is started in interactive mode so that commands can be typed into the console.
* As before the container is given a unique name and host name on the overlay network using the `--name=coh2 --hostname=coh2` arguments.
* The container is attached to the same overlay network as the storage member using the `--net=coh-net` argument.
* The container is configured to act as a client using the `-Dcoherence.client=remote` system property
* The WKA property `-Dcoherence.wka=coh1` is set so that the client can locate the cluster.

When the command is run the CachFactory console should start and display the `Map (?): ` prompt.

3. Create a cache in the console using the following command:

```
Map (?): cache foo
```
This command will cause the client to connect to the Extend proxy and create a cache called `foo`, if everything works the command prompt will have changed to `Map (foo):`.

4. Information about the cache service for the cache just created can be displayed using the service command:

```
Map (foo): service
```
Which will display something like the following:
```
Map (foo): service
SafeCacheService: RemoteCacheService(Name=RemoteCache)
[Member(Id=2, Timestamp=2016-05-17 13:25:00.271, Address=10.0.1.3:41302, MachineId=44598, Location=machine:coh2,process:1, Role=CoherenceConsole)]

Map (foo):
```
The service type is a `RemoteCacheService` so the containerized client has connected to a Proxy in exactly the same way that Coherence would work if it was not running inside containers.

##Containerized Extend Client with Non-Containerized Cluster
An Extend client application that is running inside a Docker container can easily connect to a cluster that is not running inside Docker. Many of the limitations imposed by Docker are only really relevant if connecting from the outside world into a container. To go the other way and connect from a container to outside everything is configured and will work as normal.

##Containerized Cluster with External Client
When connecting a non-containerized client to a containerized cluster the configuration above will not work, again due to limitation of the way that Docker virtualizes the containers network and the use of NAT'ing to expose the container to the outside world.

In the example above Coherence used the default configuration for the Proxy and the client where the Proxy listens on an ephemeral port and the client locates this port using the NameService after locating the cluster. When using Docker Coherence cannot be configured to use ephemeral ports due to the limitation of having to specify which ports a container will expose at the point when the container is started; this means that the Proxy must be configured to listen on a specific port. The reason Coherence uses ephemeral ports is that it makes Coherence much easier to use as there will not be issues with port clashes due to multiple proxies being configured with the same port. When running in Docker it all of the proxies can be configured to use the same specific port because each container is isolated from the others so there will be no contention for ports.

To be accessible from outside of the container a Proxy needs to be configured to listen on a specific port as in the example below:
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
In the above configuration the Proxy will listen on port 20000 on any local address.

Another limitation imposed by the use of NAT'ing by Docker is that the Coherence's built in load balancer must be set to `client` as in the example above. This is because Coherence does not know that it is running inside a container and as far as it knows the Proxy is listening on the internal IP addresses of the container. The Coherence load balance will send an internal IP address back to the client to load balance to but the client cannot connect to these addresses, the client must use the NAT'ed addresses. By setting the load balancer to `client` the server will not try to load balance clients to another Proxy.

Extend clients must be configured with a specific set of proxy addresses to connect to when connecting to a containerized cluster. The NameService cannot be used as the NameService is part of the cluster and does not know anything about the external NAT'ed addresses and ports. The client must be configured using either an AddressProvider or a fixed set of addresses, for example:
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

Alternatively a custom `AddressProvider` could be used, especially if your Docker infrastructure has a facility to provide service discovery to allow applications to discover the port mappings for a containerized service, for example if there was a class called `com.example.DockerAddressProvider` that looked up services via a remote discovery mechanism the client could be configured like this:
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

### Recap of the Important Points
Oracle Coherence Extend clients will work providing the following points are noted
1. If both client and proxy are containerized attached to the same overlay network then all Coherence *Extend features will work.
1. If the client is containerized and the proxy is not running in a container then all Coherence *Extend features will work.
2. If connecting from a non-containerized client to a containerized proxy the `<load-balancer>client<load-balancer>` setting must be used in the proxy configuration
2. If connecting from a non-containerized client to a containerized proxy  the NameService cannot be used by the client to lookup Extend proxies. Proxy addresses must be specifically set either in the client configuration or by using an AddressProvider.
