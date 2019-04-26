#Running the Coherence Docker Image

##Start a Basic Storage Enabled DefaultCacheServer
If the Coherence Docker image is run out of the box using Docker run then by default this will start a storage enabled DefaultCacheServer process. The script in the image uses arguments and environment variables to control its operations. The full run command format is

```
docker run [docker-args] \
   [-e COH_WKA=<wka-address>] \
   [-e JAVA_OPTS=<opts>] \
   [-e COH_EXTEND_PORT=<port>] \
   [-v <lib-dir>:/lib ] \
   [-v <config-dir>:/conf] \
   oracle/coherence:12.2.1.3.0-standalone [type] [args]
```

All of the arguments shown above are optional. For example:
 
`docker run -d oracle/coherence:12.2.1.3.0-standalone`

The above command will start a storage enabled DefaultCacheServer.

##Clustering
Because container environments such as Docker typically do not work with multicast Coherence must use well know addresses for cluster discovery. By setting the `COH_WKA` environment variable in the Docker run command it is possible to pass in the address that should be used for WKA. For example:
     
`docker run -d -e COH_WKA=foo.oracle.com oracle/coherence:12.2.1.3.0-standalone`

where the `foo.oracle.com` address will be used for cluster discovery. In environments that can map a DNS lookup to multiple addresses (for example Docker Swarm) then all of the addresses returned by the DNS lookup will be used by Coherence for cluster discover. For example, in Docker Swarm if a service is created called `datagrid` then Docker DNS allows all the IP addresses of the services' containers to be looked up with the address `tasks.datagrid` so this can be used in the service create command like this:
  
```
docker service create --name datagrid --network coh-net \
     -e COH_WKA=tasks.datagrid --replicas=3 oracle/coherence:12.2.1.3.0-standalone
```  

The command above will create a Docker service with three storage enabled cluster members that will all use the `tasks.datagrid` DNS lookup to discover the addresses of the other cluster members. The service can then be easily scaled up and down.
     
##Java Options
It is possible to pass in different options to the JVM and set System properties, for example heap settings or Coherence properties. This can be done by setting the `JAVA_OPTS` environment variable. For example:
     
`docker run -d -e JAVA_OPTS="-Xmx1G -Xms1G" oracle/coherence:12.2.1.3.0-standalone`
     
The above command sets the heap size to 1GB.

```
docker run -d -e JAVA_OPTS="-Dcoherence.role=storage -Dcoherence.cluster=datagrid" \
     oracle/coherence:12.2.1.3.0-standalone
```
The above command passes system properties to Coherence. Any valid JVM argument or propery may be passed in to the `JAVA_OPTS` variable.
      
##Using Coherence *Extend
The cache configuration file used by the script in the image is the file from the Coherence jar. By default this starts an Extend proxy service that will listen on an ephemeral port. Normally and Extend client will discover the set of Extend ports using the Coherence NameService. If the Extend client application is running inside another container on the same network that the storage member containers are on then this will all work correctly. But, if the Extend client is outside of the cluster's network then a fixed port needs to be used for the Extend Proxy service so that it can be exposed by Docker. This is done using the `COH_EXTEND_PORT` environment variable; for example:

```
docker run -d -p 20000:20000 -e COH_EXTEND_PORT=20000 oracle/coherence:12.2.1.3.0-standalone
```
The above command sets the Extend port to 20000 and the Docker `-p` option is used to make sure that Docker maps this port onto the host.

If using Docker Swarm is is possible to expose the Extend port in the service, for example:
```
docker service create --name datagrid --network coh-net \
     -e COH_EXTEND_PORT=20000 --publish 20000
     -e COH_WKA=tasks.datagrid --replicas=3 oracle/coherence:12.2.1.3.0-standalone
```  
Docker will now take care of exposing the Etxend port for the `datagrid` service.

##Adding To The JVM ClassPath
Typically when building an application that will use Coherence in Docker a custom image will be built, probably using the official Coherence image as the base, and then adding any application jar files, configuration and start scripts on top. For development and experimentation it is possible to run a container from the default image and map extra jar files onto the classpath. The shell script in the image adds the `/conf` folder and all jar files in the `/lib` folder to the front of the classpath. These folders can be mapped to folders on the host that might contain custom configurations and code. For example:
  
```
docker run -d -v /dev/my-project/lib:/lib \
    -v /dev/my-project/config:/conf \
    oracle/coherence:12.2.1.3.0-standalone
```  
The command above will map the `/dev/my-project/lib` folder on the host to the `/lib` folder in the container so any jar file in the `/dev/my-project/lib` folder will be on the Coherence DefaultCacheServer classpath. It will also map the `/dev/my-project/config` folder on the host to the `/conf` folder in the container so any configuration files in this folder will also be on the classpath.
          
##Container Arguments
Any arguments appended to the end of the Docker run command are passed to the shell script as usual with Docker run. These arguments are then passed to the start class's main method as command line arguments. This applies to all arguments except for the the first argument when it matches a vaild process type that the shell script recognises; these are `server` `console` and `queryplus`. These arguments control the type of process started.

###Start a DefaultCacheServer
The `server` parameter tells the shell script to start a DefaultCacheServer. This is also the default so can be omitted if desired.

###Start a Coherence Console
The `console` parameter starts a Coherence CacheFactory console and typically this would be started interactively; for example:

`docker run -it oracle/coherence:12.2.1.3.0-standalone console`

The above command will start the Docker in interactive mode and run the Coherence CacheFactory console.

###Start Coherence QueryPlus
The `queryplus` parameter starts a Coherence QueryPlus console and again typically this would be started interactively; for example:

`docker run -it oracle/coherence:12.2.1.3.0-standalone queryplus`

The above command will start the Docker in interactive mode and run the Coherence QueryPlus console. Because subsequent parameters are passed to the main class as parameters is is possible to pass in any valid QueryPlus parameter; for example:

`docker run -it oracle/coherence:12.2.1.3.0-standalone queryplus -t`

In the above command the `-t` parameter is passed to QueryPlus to enabled trace output.  


