#JMX Monitoring in Docker

The majority of monitoring tools for Oracle Coherence use JMX to gather statistics about the cluster and this section covers ways to make JMX work inside Docker containers.

If using host networking when running containers, then JMX with RMI works as normal because there is no network virtualization involved and in particulaer no NAT'ing of addresses and ports. If not using host networking and when trying to connect an external JMX client to a containerized MBean server, then there are potential issues. The information in this section is not specific to Coherence and in fact applies to any Java application wanting to use JMX inside Docker. The limitations discussed are due to the way that JMX uses RMI by default and the way that Docker virtualizes networks.

When using JMX RMI, the JVM requires two ports: one for the server connection and one for RMI. This means that when running in a Docker container these ports need to be exposed and NAT'ed by Docker to ports on the host. The issue comes when a JMX client makes a connection to a server that uses RMI. The client first connects to the server on the server connection port, which works in Docker as this connection can be made using the host IP address and NAT'ed port. The next step is that the server returns to the client the address of the RMI server and this is the internal address and port known to the JVM inside the container. The JVM expects the client to connect back on this socket address for RMI operations. However, the problem is that this address is not visible outside of the container.

## Use Fixed Port Mappings
 The first solution is to use fixed port mappings when running the container so that Docker maps the ports in the container to the exact same port on the host. The following properties need to be set in the containerized JVM:

```
 -Djava.rmi.server.hostname=<host-ip-address>
 -Dcom.sun.management.jmxremote.port=<remote-port>
 -Dcom.sun.management.jmxremote.rmi.port=<rmi-port>
```

For example, if the Docker host was using 192.168.0.10 and the ports were 3000 and 9000 the properties would be set as:

```
 -Djava.rmi.server.hostname=192.168.0.10
 -Dcom.sun.management.jmxremote.port=3000
 -Dcom.sun.management.jmxremote.rmi.port=9000
```

Then when running the container, the ports are exposed and mapped to the same ports on the host. For example:

`$ docker run -p 3000:3000 -p 9000:9000 oracle/coherence:12.2.1.3.0-standalone`

The disadvantage with this approach is that using fixed ports makes containers less portable or port management on the Docker hosts more complicated.

# Use an Alternative Transport - JMXMP
The second solution is to use an alternative transport to RMI, such as JMXMP. The advantage of JMXMP is that it is based on TCP and Java serialization and only requires a single port (ideal for Docker).

Although JMXMP is stable and has existed for some time, it is not one of the default transports built in to the JVM so it must be obtained as a separate jar file and built in to the Docker images. The ideal place to do this would be in the Java base images so that it is available to all images built on top of the base image.

The JMXMP implementation is available as an optional part of GlassFish available from [Maven Central](http://repo1.maven.org/maven2/org/glassfish/external/opendmk_jmxremote_optional_jar/1.0-b01-ea/) with these corrdinates:

```
<dependency>
  <groupId>org.glassfish.external</groupId>
  <artifactId>opendmk_jmxremote_optional_jar</artifactId>
  <version>1.0-b01-ea</version>
</dependency>
```

##Using JMXMP with Coherence
The JMXMP implementation JAR can be built into an image so that it can be added to the class path of the Coherence processes that are to be monitored inside Docker containers.

To make JMXMP work with Coherence, there must be an JMXMP MBean connector server running in the JVM that JMX clients can connect to from outside of the container. This requires a simple class adding to the Coherence application to start the JMX server and Coherence makes it very simple to add in as there is already a hook in the configuration.

The Coherence operational configuration in the `tangosol-coherence.xml` file contains a section named `<management-config>` which contains an element like this:

```
<server-factory>
  <class-name system-property="coherence.management.serverfactory"</class-name>
</server-factory>
```

This allows applications to specify a custom implementation of `com.tangosol.net.management.MBeanServerFinder` which by default is blank. A custome class can be specified in the overrides file or using the `coherence.management.serverfactory` system property. The server factory is documented in the Coherence documentation in a section called [Using an Existing MBean Server](https://docs.oracle.com/middleware/1212/coherence/COHMG/jmx.htm#COHMG5570).

An example of a Maven project to build a suitable class is included under the [code](code) section.

###Running the Example
There is an example Dockerfile in the [dockerfiles](dockerfiles) folder that builds an image containing the parts described above. To build this image, follow these steps:

1. Set up the Docker environment as described in the [Setup](../0.setup) section.

2. Open a console in the Monitoring section's [dockerfiles](dockerfiles) folder and run:
    
    `$ sh buildDockerImage.sh`

    The doeckerfiles folder includes a JAR containing the example JMXMP `MBeanServerFinder` implementation and a copy of the `opendmk_jmxremote_optional_jar-1.0-b01-ea.jar` that will be built into an image called `oracle/coherence-jmx-example:1.0`.
     
3. Run a `DefaultCacheServer` instance with the settings required to use JMXMP and expose a port for JMX using this command:

    ```
    docker $(docker-machine config coherence-test-0) run -d -p 9001 \
    --name=cohjmx oracle/coherence-jmx-example:1.0 \
    /usr/java/default/bin/java \
    -cp /u01/oracle/oracle_home/coherence/lib/coherence.jar:/lib/coherence-examples-jmx-1.0-SNAPSHOT.jar:/lib/opendmk_jmxremote_optional_jar-1.0-b01-ea.jar \
    -Dcoherence.management.remote=true \
    -Dcoherence.management.serverfactory=com.tangosol.coherence.examples.JmxmpServer \
    -Dcoherence.jmxmp.port=9001 \
    -Dcom.sun.management.jmxremote=true \
    -Dcom.sun.management.jmxremote.authenticate=false \
    -Dcom.sun.management.jmxremote.ssl=false \
    com.tangosol.net.DefaultCacheServer
    ```

    The command does the following:
    
    * Exposes the container port 9001 using the `-p 9001' argument and maps it to an ephemeral port on the Docker host.
    
    * Names the container `cohjmx` with the `--name=cohjmx' argument.
    
    * Runs Java from the location that the JRE was installed in the Java 8 base image.
    
    * Sets the class path to include `coherence.jar` from the Coherence install location in the Coherence standalone image and also includes the two jar files added in the JMX demo image.
    
    * Sets the System properties to enable Coherence to use JMX, including setting the `coherence.jmxmp.port` property to the mapped port value 9001, which is used by the example `JmxmpServer` class to configure the listen port for the JMXMP server.
     
4. Find the port that Docker has mapped the container port 9001 to by using the following command:

    `docker $(docker-machine config coherence-test-0) port cohjmx`
    
    The output is similar to the following (the actual ephemeral port used is likely to be different)
    
    ```
    9001/tcp -> 0.0.0.0:32769
    ```

    In this case, Docker has mapped port 9001 in the container to port 32769 on the Docker host. If the Docker host had an IP address of `192.168.99.102` then the JMX URL to connect to the container would be `service:jmx:jmxmp://192.168.99.102:32769`.
    
5. In order to run JConsole or JVisualVM and connect to the JMX server in the container, they must have the `opendmk_jmxremote_optional_jar-1.0-b01-ea.jar` on their classpath. Either tool can be run with the following commands:
  
  JConsole: 
    
    `$ jconsole -J-Djava.class.path="$JAVA_HOME/lib/jconsole.jar:$JAVA_HOME/lib/tools.jar:opendmk_jmxremote_optional_jar-1.0-b01-ea.jar"`
    
  JVisualVM:
  
    `$ jvisualvm -cp "$JAVA_HOME/lib/tools.jar:opendmk_jmxremote_optional_jar-1.0-b01-ea.jar"`
    
  Once JConsole or JVisualVM has starts, it should be possible to connect them to the JVM inside the container using the URL `service:jmx:jmxmp://192.168.99.102:32769`  
    
6. The JMX container can be cleaned up and removed with the following commands:

    `$ docker $(docker-machine config coherence-test-0) stop cohjmx`
    
    `$ docker $(docker-machine config coherence-test-0) rm cohjmx`