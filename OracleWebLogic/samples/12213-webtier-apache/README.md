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

        $ docker run -d -e WEBLOGIC_HOST=<host> -e WEBLOGIC_PORT=<port> -p 80:80 oracle/apache:12.2.1.3

Run an Apache image to proxy and load balance to a list of managed servers in a cluster.
        Use a list of hosts and ports

        $ docker run -d -e WEBLOGIC_CLUSTER=host1:port,host2:port,host3:port -p 80:80 oracle/apache:12.2.1.3

        Or use a cluster URL if it is available

        $ docker run -d -e WEBLOGIC_CLUSTER=<cluster-url> -p 80:80 oracle/apache:12.2.1.3

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

        $ docker run -d -e ADMIN_USERNAME=weblogic \
                     -e ADMIN_PASSWORD=welcome1 \
                     -e DOMAIN_HOME=/u01/oracle/user_projects/domains/abc_domain \
                     -e DOMAIN_NAME=abc_domain \
                     -p 7001:7001 \
                     store/oracle/weblogic:12.2.1.3

Start an Apache container by calling:

        $ docker run -d --name apache \
                     -e WEBLOGIC_HOST=<admin-host> \
                     -e WEBLOGIC_PORT=7001 \
                     -p 80:80 \
                     oracle/apache:12.2.1.3

Now you can access the WebLogic Admin Console under **http://localhost/console** (default to port 80) instead of using port 7001. You can access the console from a remote machine using the weblgoic admin server's `<admin-host>` instead of `localhost`.

## Provide Your Own Apache Plugin Configuration
If you want to start the Apache container with some pre-specified `mod_weblogic` configuration:

* Create a `custom_mod_wl_apache.conf` file by referring to `custom_mod_wl_apache.conf.sample` and Chapter 3 @ Fusion Middleware Using Oracle WebLogic Server Proxy Plug-Ins documentation. [https://docs.oracle.com/middleware/12213/webtier/develop-plugin/apache.htm#GUID-231FB5FD-8D0A-492A-BBFD-DC12A31BF2DE]

* Place the `custom_mod_wl_apache.conf` file in a directory `<host-config-dir>` on the host machine and then mount this directory into the container at the location `/config`. By doing so, the contents of host directory `<host-config-dir>` (and hence `custom_mod_wl_apache.conf`) will become available in the container at the mount point.

This mounting can be done by using the -v option with the `docker run` command as shown below. 

        $ docker run -v <host-config-dir>:/config -w /config \
                     -d -e WEBLOGIC_HOST=<admin-host> \
                     -e WEBLOGIC_PORT=7001 \
                     -p 80:80 oracle/apache:12.2.1.3

Note: you can also mount the file directly as follows.

        $ docker run \
            -v <host-config-dir>/custom_mod_wl_apache.conf:/config/custom_mod_wl_apache.conf  \
            -w /config -d -e WEBLOGIC_HOST=<admin-host> \
            -e WEBLOGIC_PORT=7001 \
            -p 80:80 oracle/apache:12.2.1.3

Once the mounting is done, the custom_mod_wl_apache.conf will replace the built-in version of the file.

## Enable SSL Access From User to Apache HTTP Server
You can enable SSL support from user to Apache HTTP server when starting the **Apache HTTP Server with WebLogic Server Proxy Plugin** in a container using the following `docker run` commands.

Use `VIRTUAL_HOST_NAME` environment variable to enable SSL. Once enabled, the Apache HTTP Server is configured to listen to port 4433 for SSL traffic.

Note: this section only demonstrates how to enable SSL from user to Apache HTTP server. In order for SSL to work from user to containerized Apache HTTP Server, and then to WebLogic domain in a container, you need to enable SSL on the WebLogic Server as well as on Apache HTTP Server with WebLogic Server Proxy Plugin.

### Auto-generate Certificates On First Startup

For demo and quick testing purposes, you could use auto-generation of the certificate and key. This option generates demo certificate and key. It is strongly recommended that you specify `--volume-driver` and `-v` to ensure that the certificates are only generated on the first startup of the container, instead of every time the Apache container is started.

        $ docker run -d --name apache \
                     -e VIRTUAL_HOST_NAME=<virtual_host_name> \ 
                     -e WEBLOGIC_HOST=<admin_host> \
                     -e WEBLOGIC_PORT=7001 \
                     -p 4433:4433 \
                     --volume-driver local \
                     -v <host-config-dir>:/config \
                     -w /config \
                     oracle/apache:12.2.1.3

Use `VIRTUAL_HOST_NAME` to specify the VirtualHostName of Apache HTTP server. If `VIRTUAL_HOST_NAME` is not set, SSL is not enabled.

This `docker run` command generates demo quality certificate and key, and put them in `/config/ssl/example.crt` and `/config/ssl/example.key` respectively.

Note that here we use host machine's `local` file system as the `volume-driver`. For details of volume and volume-driver, please refer to Docker documentation. 

Automatically generated certificates are only for demo and quick testing purposes. They do not offer the level of security that is usually required in production.  See `container-scripts/certgen.sh` for details of the auto-generated certificates.

### Provide Your Own Certificates
In production, Oracle strongly recommend that you provide your own certificates using the following `docker run` command.

        $ docker run -d --name apache \
                     -e VIRTUAL_HOST_NAME=<virtual_host_name> \ 
                     -e SSL_CERT_FILE=<ssl-certificate-file> \ 
                     -e SSL_CERT_KEY_FILE=<ssl-certificate-key-file> \ 
                     -e WEBLOGIC_HOST=<admin_host> \
                     -e WEBLOGIC_PORT=7001 \
                     -p 4433:4433 \
                     oracle/apache:12.2.1.3

Use `SSL_CERT_FILE` and `SSL_CERT_KEY_FILE` to specify the name of the certificate and key files, including the path in the container's file system. Both of the environment variables need to be set.

Note that if the certificate or/and key file does not exist, the startup of the Apache container will fail. 

Once Apache is running in a container, you can access the WebLogic Admin Console under **`https://<virtual-host-name>:4433/console/console.portal`**. 

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


