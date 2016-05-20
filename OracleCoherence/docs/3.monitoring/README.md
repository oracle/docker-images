#JMX Monitoring in Docker
The majority of monitoring tools for Oracle Coherence use JMX to gather statistics about the cluster and this section covers ways to make JMX work inside Docker containers.

The information in this section is not specific to Coherence and in fact apply to any Java application wanting to use JMX inside Docker. The limitations discussed are due to the way that JMX uses RMI by default and the way that Docker virtualizes networks.

When using JMX RMI the JVM requires two ports, one for the server connection and one for RMI. This means that when running in a Docker container these ports would need to be exposed and NAT'ed by Docker to ports on the host. The issue comes when a JMX client makes a connection to a server that will use RMI. The client first connects to the server on the server connection port, which will work in Docker as this connection can be made using the host IP address and NAT'ed port. The next step is that the server then returns to the client the address of the RMI server and this will be the internal address and port known to the JVM inside the container. The JVM expects the client to connect back on this socket address for RMI operations, the problem is that this address is not visible outside of the container.

 ##Use Fixed Port Mappings
 The first solution is to use fixed port mappings when running the container so that Docker maps the ports in the container to the exact same port on the host. The following properties would need to be set in the containerized JVM:
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
The when running the container we eould expose the ports and map them to the same ports on the host, for example:
```
$ docker run -p 3000:3000 -p 9000:9000 oracle/coherence:12.2.1.0.0-standalone
```

The disadvantage with this approach is that using fixed ports makes containers less portable or port management on the Docker hosts more complicated.

#Use an Alternative Transport - JMXMP
The second solution is to use an alternative transport to RMI, one such alternative being JMXMP. The advantage of JMXMP is that it is TCP and Java serialization based and only requires a single port; which is ideal for Docker.

Although JMXMP is stable and has existed for some time it is not one of the default transports built in to the JVM so it must be obtained as a separate jar file and built in to the Docker images. The ideal place to do this would be in the Java base images so that it is available to all images built on top of the base image.

The JMXMP implementation is available as an optional part of GlassFish available from [Maven Central](http://repo1.maven.org/maven2/org/glassfish/external/opendmk_jmxremote_optional_jar/1.0-b01-ea/) with these corrdinates:
```
<dependency>
  <groupId>org.glassfish.external</groupId>
  <artifactId>opendmk_jmxremote_optional_jar</artifactId>
  <version>1.0-b01-ea</version>
</dependency>
```

##Using JMXMP with Coherence
The a JMXMP implementation jar can be built into an image so that it can be added to the class path of the Coherence processes that are to be monitored inside Docker containers.

To make JMXMP work with Coherence there must be an JMXMP MBean connector server running in the JVM that JMX clients can connect to from outside of the container. This requires a simple class adding to the Coherence application to start the JMX server and Coherence makes it very simple to add in as there is already a hook in the configuration.

The Coherence Operational Configuration in the tangosol-coherence.xml file contains a section tagged `<management-config>` which contains an element like this:
```
<server-factory>
  <class-name system-property="coherence.management.serverfactory"</class-name>
</server-factory>
```
This allows applications to specify a custom implementation of `com.tangosol.net.management.MBeanServerFinder` which by default is blank. A custome class can be specified in the overrides file or using the `coherence.management.serverfactory` system property. The server factory is is documented in the Coherence documentation in a section called [Using an Existing MBean Server](https://docs.oracle.com/middleware/1212/coherence/COHMG/jmx.htm#COHMG5570).

An example of a Maven project to build a suitable class is included under the [code](code) section.

###Running the Example
There is an example Dockerfile in the [dockerfiles](dockerfiles) folder that will build an image containing the parts described above. To build this image follow these steps:

1. Make sure that the oracle/coherence:12.2.1.0.0-standalone image is already built as described in main [OracleCoherence](../..) section.

2. Open a console in the [dockerfiles](dockerfiles) folder and run:
```
$ sh buildDockerImage.sh
```

3. Run a DefaultCacheServer with the settings required to use JMXMP and expose a port for JMX using this command:

