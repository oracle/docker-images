Sample Image with a WLS Domain and Coherence
===============================

This sample demonstrates how to create a WLS 12.2.1.3 domain with a Coherence cluster with WDT and run it 
inside docker containers.  The sample also includes a Coherence proxy server that runs inside the domain, along
with a proxy client to access a Coherence cache.  The image created in this sample can also be used to create a domain
using Kubernetes.  For more information on WDT, refer to https://github.com/oracle/weblogic-deploy-tooling.  For 
more information on using WebLogic on Kubernetes, see https://github.com/oracle/weblogic-kubernetes-operator.

### WDT Model File and Property Files

The image created in this sample, using WDT, has both the WebLogic binary home and domain home.  The WDT input file, `cohDomain.yaml`, 
describes the configuration of the domain, which specifies a WebLogic dynamic cluster with a maximum of
five managed servers.  The domain will also have a Coherence cluster scoped to the servers running in that dynamic cluster.

The sample includes `properties` files needed to create the domain.  The files already have
the correct values for the sample, you do not need to modify them. 
The files are `adminuser.properties` and the `adminpass.properties` in the `properties/docker_build` directory.
Care should be taken to secure the credentials that are present in the model. The ADMIN credential 
attributes in the sample model have a file token referencing a special property file. Each special 
property file must only contain a single property and can be created and modified using a text editor. 

The sample also provides `security.properties` in the `properties/docker-run` directory. This file contains 
the admin credentials and additional properties used to customize the WebLogic Server start.
The ADMIN credentials are necessary to start the Administration or Managed Server in a Docker container.   
It is the responsibility of the user to manage this volume, and the security.properties, in the container.

**Note**: Oracle recommends that the `adminpass.properties`, `adminuser.properties`, and `security.properties` files 
be deleted or secured after the image is built and the WebLogic Server is started so that the user name 
and password are not inadvertently exposed.

## How to Build and Run

**NOTE:** The image is based on the following WebLogic Server image: 
    `container-registry.oracle.com/middleware/weblogic:12.2.1.3`  
Use `docker pull` to load that image into your local repository before building this sample.

The WebLogic Deploy Tool installer, with a minimum version of 1.3.0, is required to build this image.
Download `weblogic-deploy.zip` to the sample directory with the following command:

    curl  -Lo ./weblogic-deploy.zip https://github.com/oracle/weblogic-deploy-tooling/releases/download/weblogic-deploy-tooling-1.3.0/weblogic-deploy.zip
     
WDT requires the deployment artifacts to be in an archive file. This archive needs to be built 
before building the Docker image. Build the archive.zip using the following command:

    ./build-archive.sh

The sample is using names and security credentials that are compatible with the WebLogic Operator `QuickStart`, 
see https://oracle.github.io/weblogic-kubernetes-operator/quickstart/.  This allows you to use this same image
to run the sample in Kubernetes.

Run the following command to build the image:

    docker build -f Dockerfile --no-cache  \
      --build-arg CUSTOM_DOMAIN_NAME=sample-domain1 \
      --build-arg WDT_MODEL=cohModel.yaml \
      --build-arg WDT_ARCHIVE=archive.zip \
      --build-arg WDT_VARIABLE=properties/docker-build/domain.properties  \
      --force-rm=true   \
       -t coherence-12213-domain-home-in-image-wdt .

Start the Administration Server:

    docker run -d --name wlsadmin --hostname wlsadmin -p 7001:7001 -v <absolute-path-sample-dir>/properties/docker-run:/u01/oracle/properties coherence-12213-domain-home-in-image-wdt

Start a Managed Server to self-register with the Administration Server.  Open the Coherence proxy port 9000 also so that the
proxy client can access the cache. Run the following command:

    docker run -d --name managed-server-1 --link wlsadmin:wlsadmin  -p 8001:8001 -p 9000:9000 -v ~/git-pfmackin-docker-images/docker-images/OracleWebLogic/samples/12213-coherence-domain-in-image-wdt/properties/docker-run:/u01/oracle/properties -e MANAGED_SERVER_NAME=managed-server-1 coherence-12213-domain-home-in-image-wdt startManagedServer.sh

Start an additional Managed Server.  There is no need to open the proxy port for this server. Run the following command:

    docker run -d --name managed-server-2 --link wlsadmin:wlsadmin -p 8002:8001 -v <absolute-path-sample-dir>/properties/docker-run:/u01/oracle/properties -e MANAGED_SERVER_NAME=managed-server-2 coherence-12213-domain-home-in-image-wdt startManagedServer.sh


Use the WebLogic console at http://localhost:7001/console to ensure that the admin server and managed servers are running.  They may take
 a few minutes to start. Once the servers are ready, you can test the Coherence cluster as follows:

Build the proxy client JAR:

    cd coh-proxy-client
    mvn package -DskipTests=true
    
Load the cache with 10,000 entries:

    java -jar target/proxy-client-1.0.jar load
 
Read each cache entry and validate the value to make sure it is correct:

     java -jar target/proxy-client-1.0.jar validate

## Summary

This sample demonstrated how to use WDT to build a WebLogic image configured with both a Coherence cluster and 
a Coherence proxy server.  We then used docker to start the admin server and two managed servers, with the first
managed server exposing port `9000` for the proxy.  Finally, the proxy client sample program was executed to load,
then validate the contents of the cache.
    

# Copyright
Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
