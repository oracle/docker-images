# Oracle Connection Manager on Container
Sample container build files to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle Database please see the [Oracle Connection Manager online Documentation](http://docs.oracle.com/en/database/).

## How to build and run
This project offers sample container files for:
  * Oracle Database 21c Client (21.3) for Linux x86-64
  * Oracle Database 19c Client (19.3) for Linux x86-64
  * Oracle Database 18c Client (18.3) for Linux x86-64
  * Oracle Database 12c Release 2 Client (12.2.0.1.0) for Linux x86-64

To assist in building the container images, you can use the [buildContainerImage.sh](dockerfiles/buildContainerImage.sh) script. See section **Create Oracle Connection Manager Image** for instructions and usage.

**IMPORTANT:** Oracle Connection Manager container is useful when you want to bind single port to host and serve many container on different ports. Oracle Connection manager provide proxy connections. If you are running Oracle RAC Database on docker/container and network is not available for users, you can use Oracle Connection Manager image to proxy the connections.

For complete Oracle Connection Manager setup, please go though following steps and execute them as per your enviornment:

### Create Oracle Connection Manager Image
**IMPORTANT:** You will have to provide the installation binaries of Oracle ADMIN Client Oracle Database 21c Client (21.3) for Linux x86-64 and put them into the `dockerfiles/<version>` folder. You  only need to provide the binaries for the edition you are going to install. The binaries can be downloaded from the [Oracle Technology Network](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html). You also have to make sure to have internet connectivity for yum. Note that you must not uncompress the binaries.

The `buildContainerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.Before you build the image make sure that you have provided the installation binaries and put them into the right folder. Go into the **dockerfiles** folder and run the **buildContainerImage.sh** script as root or with sudo privileges:

```
./buildContainerImage.sh -v (Software Version)
./buildContainerImage.sh -v 21.3.0
```
For detailed usage of command, please execute following command:
```
./buildContainerImage.sh -h
```

### Create Network Bridge
Before creating container, create the bridge. If you are using same bridge with same network then you can use same IPs mentioned in **Create Containers** section.

```
docker network create --driver=bridge --subnet=172.16.1.0/24 rac_pub1_nw
```

**Note:** You can change subnet according to your environment.

### Create Containers.
Execute following command as root user to create connection manager container.

```
/usr/bin/docker run -d --hostname racnode-cman1 --dns-search=example.com \
--network=rac_pub1_nw --ip=172.16.1.15 \
-e DOMAIN=example.com -e PUBLIC_IP=172.16.1.15 \
-e PUBLIC_HOSTNAME=racnode-cman1 -e SCAN_NAME=racnode-scan \
-e SCAN_IP=172.16.1.70 --privileged=false \
-p 1521:1521 --name racnode-cman oracle/client-cman:21.3.0
```

In the above container, you can see that we are passing env variables using "-e". You need to change PUBLIC_IP, PUBLIC_HOSTNAME, SCAN_NAME, SCAN_IP according to your environment. Also, container will be binding to port 1521 on your docker host.

**Note:** SCAN_NAME and SCAN_IP will be your Oracle RAC SCAN details. These will be registered in connection manager but will be accessible when you create Oracle RAC container.

To check the Cman container/services creation logs , please tail docker logs. It will take 2 minutes to create the Cman container service.

```
docker logs racnode-cman
```

You should see following when cman container setup is done:

```
###################################
CONNECTION MANAGER IS READY TO USE!
###################################
```
