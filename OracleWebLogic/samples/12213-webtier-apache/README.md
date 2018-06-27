Apache HTTP Server with Oracle WebLogic Server Proxy Plugin on Docker
===============
This project includes a quick start Dockerfile and samples for standalone Apache HTTP Server with 12.2.1.3.0 Oracle WebLogic Server Proxy Plugin based on Oracle Linux. The certification of Apache on Docker does not require the use of any file presented in this repository. Customers and users are welcome to use them as starters, and customize/tweak, or create from scratch new scripts and Dockerfiles.

## Build Apache With Plugin Docker Image

This project offers a Dockerfile for Apache HTTP Server with Oracle WebLogic Server Proxy Plugin in standalone mode. To assist in building the images, you can use `buildDockerImage.sh` script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call docker build with their preferred set of parameters.

IMPORTANT: You have to download the **Oracle WebLogic Server Proxy Plugin 12.2.1.3.0** package (see .download file) and drop them in this directory.

Run `buildDockerImage.sh` script.

        $ sh buildDockerImage.sh 

## Run Apacher HTTP Server in a Container 

Run an Apache container to access an admin server, or a managed server in a non-clustered environment, that is running on `<host>` and listening to `<port>`.

        $ docker run -d -e WEBLOGIC_HOST=<host> WEBLOGIC_PORT=<port> -p 80:80 12213-apache

Run an Apache image to proxy and load balance to a list of managed servers in a cluster
     
        Use a list of hosts and ports.

        $ docker run -d -e WEBLOGIC_CLUSTER=host1:port,host2:port,host3:port -p 80:80 12213-apache

        Or use a cluster URL if it is available

        $ docker run -d -e WEBLOGIC_CLUSTER=<cluster-url> -p 80:80 12213-apache

The values of **WEBLOGIC_CLUSTER** must be valid, and correspond to existing containers running WebLogic servers.

### Admin Server Only Example

First make sure you have the WebLogic Server 12.2.1.3 install image, pull the WebLogic install image from the DockerStore `store/oracle/weblogic:12.2.1.3`, or build your own image `oracle/weblogic:12.2.1.3-developer` at [https://github.com/oracle/docker-images/tree/master/OracleWebLogic/dockerfiles/12.2.1.3].

Start a container from the WebLogic install image. You can override the default values of the following parameters during runtime with the -e option:

        ADMIN_NAME (default: AdminServer)
        ADMIN_PORT (default: 7001)
        ADMIN_USERNAME (default: weblogic)
        ADMIN_PASSWORD (default: Auto Generated)
        DOMAIN_NAME (default: base_domain)
        DOMAIN_HOME (default: /u01/oracle/user_projects/domains/base_domain)

NOTE: To set the DOMAIN_NAME, you must set both DOMAIN_NAME and DOMAIN_HOME.

        $ docker run -d -e ADMIN_USERNAME=weblogic -e ADMIN_PASSWORD=welcome1 -e DOMAIN_HOME=/u01/oracle/user_projects/domains/abc_domain -e DOMAIN_NAME=abc_domain -p 7001:7001 store/oracle/weblogic:12.2.1.3

Start an Apache container by calling:

        $ docker run -d --name apache -e WEBLOGIC_HOST=<admin-host> -e WEBLOGIC_PORT=7001 -p 80:80 12213-apache

Now you can access the WebLogic Admin Console under **http://localhost/console** (default to port 80) instead of using port 7001. You can access the console from a remote machine using the weblgoic admin server's `<admin-host>` instead of `localhost`.

## Provide Your Own Apache Plugin Configuration
If you want to start the Apache container with some pre-specified `mod_weblogic` configuration:

* Create a `custom_mod_wl_apache.conf` file by referring to `custom_mod_wl_apache.conf.sample` and Chapter 3 @ Fusion Middleware Using Oracle WebLogic Server Proxy Plug-Ins documentation. [https://docs.oracle.com/middleware/12213/webtier/develop-plugin/apache.htm#GUID-231FB5FD-8D0A-492A-BBFD-DC12A31BF2DE]

* Place the `custom_mod_wl_apache.conf` file in a directory `<host-config-dir>` on the host machine and then mount this directory into the container at the location `/config`. By doing so, the contents of host directory `<host-config-dir>` (and hence `custom_mod_wl_apache.conf`) will become available in the container at the mount point.

This mounting can be done by using the -v option with the `docker run` command as shown below. 

        $ docker run -v <host-config-dir>:/config -w /config -d -e WEBLOGIC_HOST=<admin-host> -e WEBLOGIC_PORT=7001 -p 80:80 12213-apache

Note: you can also mount the file directly as follows.

        $ docker run -v <host-config-dir>/custom_mod_wl_apache.conf:/config/custom_mod_wl_apache.conf -w /config -d -e WEBLOGIC_HOST=<admin-host> -e WEBLOGIC_PORT=7001 -p 80:80 12213-apache

Once the mounting is done, the custom_mod_wl_apache.conf will replace the built-in version of the file.

## Enable SSL Access From User to Apache HTTP Server
You can enable SSL support from user to Apache HTTP server when start **Apache HTTP Server with Plugin** in a container using the following `docker run` commands.

Note that the Apache HTTP Server is configured to listen to port 4433 for SSL traffic.

### Use Built-in Example Certificate
The minimum requirement of turning on SSL support is to set the VIRTUAL_HOST_NAME environment variable when start Apache in a container.

	$ docker run -d --name apache \
          -e VIRTUAL_HOST_NAME=<virtual_host_name> \ 
          -e WEBLOGIC_HOST=<admin_host> \
          -e WEBLOGIC_PORT=7001 \
          -p 4433:4433 \
          store/oracle/apache:12.2.1.3

Where `VIRTUAL_HOST_NAME` specifies the VirtualHostName of Apache HTTP server. If `VIRTUAL_HOST_NAME` is not set, SSL from the user to Apache is disabled.

This approach uses the built-in example certificate (`example.cert` and `example.key`), which is only for demo and quick testing purposes. It does not offer the level of security that is usually required in production. 

### Provide Your Own Certificate
In production, Oracle strongly recommend that you provide your own certificate using the following `docker run` command.

	$ docker run -d --name apache \
          -e VIRTUAL_HOST_NAME=<virtual_host_name> \ 
          -e SSL_CERT_FILE=<ssl-certificate-file> \ 
          -e SSL_CERT_KEY_FILE=<ssl-certificate-key-file> \
          -e WEBLOGIC_HOST=<admin_host> \
          -e WEBLOGIC_PORT=7001 \
          -p 4433:4433 \
          store/oracle/apache:12.2.1.3

Where the additional environment variables `SSL_CERT_FILE` and `SSL_CERT_KEY_FILE` specify the name with full path of the SSL certificate and key file respectively. Note that here we use host machine's local file system as the `volume-driver`. For details of Volume and Volume Driver, please refer to Docker documentation.

If `SSL_CERT_FILE` and `SSL_CERT_KEY_FILE` are set, but the files do not exist, the startup of the Apache container will fail. Optionally you can turn on auto-generation as described below.

### Auto-generate a Certificate On First Startup

If desired, you could turn on auto-generation of the certificate and key by adding `-e GENERATE_CERT_IF_ABSENT=true`. This option will generate a demo certificate and key if the specified files are absent. In this scenario, it is strongly recommended that you specify `--volume-driver` and `-v` to ensure that the certificate is only generated on the first startup of the container, instead of every time the Apache container is started.

	$ docker run -d --name apache \
          -e VIRTUAL_HOST_NAME=<virtual_host_name> \ 
          -e SSL_CERT_FILE=<ssl-certificate-file> \ 
          -e SSL_CERT_KEY_FILE=<ssl-certificate-key-file> \
          -e GENERATE_CERT_IF_ABSENT=true \
          -e WEBLOGIC_HOST=<admin_host> \
          -e WEBLOGIC_PORT=7001 \
          -p 4433:4433 \
          --volume-driver local \
          -v <host-config-dir>:/config \
          -w /config store/oracle/apache:12.2.1.3

Where `SSL_CERT_FILE` and `SSL_CERT_KEY_FILE` specifies the name with full path of the SSL certificate and key file respectively. Note that here we use host machine's local file system as the `volume-driver`. 

Similar to the built-in example SSL certificate, an auto-generated certificate is only for demo and quick testing purposes. 


Once Apache is running in a container, you can access the WebLogic Admin Console under **`https://<virtual-host-name>:4433/console`**. The <virtual-host-name> needs to be the same as what is set to `VIRTUAL_HOST_NAME` environment variable. Note that if SSL is not enabled between Apache HTTP server and WebLogic Domain, you need to access the console under **`https://<virtual-host-name>:4433/console/login/LoginForm.jsp`**.

**Note:** the usual procedure of applying the certificate on the client side needs to be followed. For example, the certificate needs to be imported into a web browser in order for a web client to access the Apache endpoint via https protocol. Follow the instructions in the vendor's documentation about importing a SSL certificate into a specific web browser. You may need to combine the certificate and key into a single file with `.pem` extension.

## Stop an Apache Instance

To stop the Apache instance, execute the following command:

        $ docker stop apache (Assuming the name of container is 'apache')

To look at the Docker Container logs run:

        $ docker logs --details <Container-id>

## Considerations When Exposing WebLogic Server Ports
IMPORTANT: although, for demonstration purposes, the examples above expose the default admin port to users outside of the Docker container where the admin server is running, Oracle recommends careful consideration before deciding to expose any administrative interfaces externally.

While it is natural to expose web applications outside a container, exposing administrative features like the WebLogic Administration Console and a T3 channel for WLST should be given more careful consideration. Similar to running a domain in a traditional data center, the same kind of considerations should be taken into account while running a WebLogic domain in a Docker container. These include various means to controlling access through T3 protocol, such as:

* Running HTTP on a separate port from T3 and other protocols.
* Not exposing T3 ports outside the firewall (i.e., expose only HTTP).
* Not enabling HTTP tunneling for T3.

If it is necessary to expose T3 outside the firewall, using two-way SSL and connection filters to ensure that only known clients can connect to T3 ports.

## License
To download and run Oracle WebLogic Server Proxy Plugins 12.2.1.3.0 Distribution regardless of inside or outside a Docker container, and regardless of the distribution, you must download the binaries from Oracle website and accept the license indicated at that page.

To download and run Oracle JDK regardless of inside or outside a Docker container, you must download the binary from Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project required to build the Docker images are, unless otherwise noted, released under the Universal Permissive License v1.0.

## Copyright
Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.


