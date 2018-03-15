Oracle Connection Manager on Docker

==========================================

Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle Database please see the Oracle Connection Manager online Documentation. (http://docs.oracle.com/en/database/)

1) How to build and run

       This project offers sample Dockerfiles for:

       Oracle Database 12c Release 2 Client (12.2.0.1.0) for Linux x86-64

     	  To assist in building the images, you can use the buildDockerImage.sh script. The buildDockerImage.sh script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call docker build with their prefered set of parameters.See below for instructions and usage.

        IMPORTANT : Oracle Connection Manager container is useful when you want to bind single port to host and serve many container on different ports. Oracle Connection manager provide proxy conections. If you are running Oracle RAC Database on docker/container and network is not available for users, you can use Oracle Connection Manager image to proxy the connections.
        For complete Oracle Connection Manager setup, please go though following steps and execute them as per your enviornment:

2) You need to make sure that you have enough memory and cpu resources available for container.

3) Create Oracle Connection Manager Image

                IMPORTANT: You will have to provide the installation binaries of Oracle ADMIN Client Oracle Database 12c Release 2 Client (12.2.0.1.0) for Linux x86-64 and put them into the (DOCKER_CMAN_IMAGE)/dockerfiles/(VERSION) folder. You  only need to provide the binaries for the edition you are going to install. The binaries can be downloaded from the Oracle Technology Network. You also have to make sure to have internet connectivity for yum. Note that you must not uncompress the binaries. The script will handle that for you and fail if you uncompress them manually!
        Before you build the image make sure that you have provided the installation binaries and put them into the right folder. Go into the dockerfiles folder and run the buildDockerImage.sh script as root or with sudo privileges:

        Change your directory to (DOCKER_CMAN_IMAGE)/dockerfile folder and execute following command:

        #./buildDockerImage.sh -v (Software Version)

        #./buildDockerImage.sh -v 12.2.0.1
        For detailed usage of command, please execute folowing command: [oracle@localhost dockerfiles]$ ./buildDockerImage.sh -h

4) Before creating container, create the bridge. Also, replace IP according to your environment. If you are using same bridge with same network then you can use same IPs mentioned in next step.

        #docker network create --driver=bridge --subnet=172.15.1.0/24 rac_pub1_nw

5) Create Containers. We are creating container in non-priv mode.

        #/usr/bin/docker run -d --hostname racnode-cman1 --dns-search=example.com \
        --network=rac_pub1_nw --ip=172.15.1.15 \
        -e DOMAIN=example.com -e PUBLIC_IP=172.15.1.15 \
        -e PUBLIC_HOSTNAME=racnode-cman1 -e SCAN_NAME=racnode-scan \
        -e SCAN_IP=172.15.1.70 --privileged=false \
        -p 1521:1521 --name racnode-cman oracle/client-cman:12.2.0.1

        In the above container, you can see that we are passing env variables using "-e". You need to change PUBLIC_IP, PUBLIC_HOSTNAME, SCAN_NAME, SCAN_IP according to your environment. Also, container will be binding to port 1521 on your docker host.
        To check the Cman container/services creation logs , please tail docker logs. It will take 2 minutes to create the Cman container service.

        #docker logs racnode-cman

6) You should see following when cman container setup is done:

        ###################################

        CONNECTION MANAGER IS READY TO USE!

        ###################################
