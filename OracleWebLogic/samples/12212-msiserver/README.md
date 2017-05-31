Example of docker images with WebLogic server in MSI Mode
=========================================================
This Dockerfile extends the Oracle WebLogic image by creating a domain that configures a managed
server in MSI mode (or Managed Server Independence mode). In this mode, a managed server can run
without the need of an admin server

How to build and run the base image
-----------------------------------
First make sure you have built **oracle/weblogic:12.2.1.2-developer**. 

Next, to build the base msi image, run:

        $ docker build -t 12212-msiserver .

Finally, to start the Managed Server in MSI mode, run:

        $ docker run -d -p 8011:8011 12212-msiserver

Connect to this container instance. You'll notice that the managed server is running from a domain
located at /u01/msi-server. Under the servers directory, you'll notice a server name that seems
randomly generated. It is of pattern ms[0-9]*. Say that your generated container id is cf579fd131fc
and you find that the random managed server name is ms3. You can verify the server is in MSI mode
by searching for a catalog message BEA-150018

$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
cf579fd131fc        12212-msiserver     "/u01/oracle/launc..."   2 minutes ago       Up 2 minutes        0.0.0.0:8011->8011/tcp   vigilant_volhard

$ docker exec -it cf579fd131fc bash

$ cat servers/ms3/logs/ms3.log | grep BEA-150018
####<May 16, 2017, 6:30:09,993 PM GMT> <Info> <Configuration Management> <cf579fd131fc> <> <Thread-11> <> <> <> <1494959409993> <[severity-value: 64] [partition-id: 0] [partition-name: DOMAIN] > <BEA-150018> <This server is being started in Managed Server independence mode in the absence of the Administration Server.> 

Also note that the this server does not have a publicly accessible URL since no application is
deployed to it yet. When additional images are created by adding application(s) to this base image
the same command (as above) may be used to launch the server and accessed using the URL
http://localhost:8011/<relevant-context-root>

Randomly generated managed server name can both be overridden using environment variable.
For example, the following command may be used to run a managed server with name ms1

docker run --name msiserver --env MS_NAME=ms1 12212-msiserver

By default, this image comes configured with 10 managed servers, ms1 to ms10. However, the image
can be built with configurable number of managed servers using NUMBER_OF_MS argument

docker build -t 12212-msiserver --build-arg NUMBER_OF_MS=15 .

How to use the base image to add application
--------------------------------------------
To build, run:
        $ docker build -t 12212-summercamps-msiserver -f Dockerfile.addapp --build-arg name=summercamps  --build-arg source=apps/summercamps.ear --build-arg simple_filename=summercamps.ear .

Dockerfile.addapp adds an app called summercamps.ear targeted to the cluster that
the managed server is a part of

To start the Managed Server in MSI mode with this app, run:

        $ docker run -d -p 8011:8011 12212-summercamps-msiserver

summercamps app will now be accessible at

http://localhost:8011/

As with the base image, you can still override managed server name and cluster name

Using swarm service creation with this image
--------------------------------------------
The image called 12212-summercamps-msiserver can be used for Docker service creation
to scale out to multiple replicas. docker service creation can only be done
using an image from a docker registry. If you don't have publishing rights to a docker
registry you can start one locally. More details can be found here
https://docs.docker.com/registry/deploying/

Here are the three steps you'll need to start, use and push to your local registry.
If you do have push rights to an existing docker registry, you can skip to the third
step

1. Start the registry
docker run -d -p 5000:5000 --restart=always --name registry registry:2

2. Change docker preferences to add this local registry to your list of insecure registries
{
  "insecure-registries" : [
    "localhost:5000"
  ]
}

3. Push to the local registry
docker tag 12212-summercamps-msiserver localhost:5000/12212-summercamps-msiserver
docker push localhost:5000/12212-summercamps-msiserver

Now that your image is published to the registry, start by joining swarm, either a swarm
leader or as a swarm worker

$ docker swarm init

Next create a service using a command like this

$ docker service create --name city_activity_guide -p 8011:8011 --hostname "msihost" --host "msihost:127.0.0.1" --env "MS_NAME=ms{{.Task.Slot}}" --replicas 3 localhost:5000/12212-summercamps-msiserver:latest

The following experimental feature in 17.03.1-ce is useful for examining logs for all
service replicas
$ docker service logs city_activity_guide

In the above example, a service is created with 3 replicas. We use templatized --env
to pass in a custom managed server name to the service. In this example a built-in
load balancer exposes port 8011. Accessing the URL will send the request to the three
replicas based on default load balancing algorithm. You should be able to see managed
server name printed in response:

$ curl http://localhost:8011/

If you use a browser, the session will be sticky. And you can see a session
variable called "Sports camps" being updated

You can scale the service using another service command. For example, you can scale up to
5 replicas using the following command

docker service scale city_activity_guide=5

Or you can scale down to say one replica

docker service scale city_activity_guide=1

If you are testing on different browser instances and you can verify that each browser is
hitting a different replica, you'll notice them all move to the same replica when you scale
down to 1

You can shutdown the service using
docker service rm city_activity_guide

Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
