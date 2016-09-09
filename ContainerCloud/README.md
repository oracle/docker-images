# Container Cloud Service Example Stacks

## Purpose

The stacks and images in this repository consist of open source images and applications which require customization before use in a demonstrable example in Container Cloud Service. While the basis for these images may be found publically, e.g. on Docker Hub, out of the box, they do not provide sufficient capabilities or configuration to demonstrate the power of the Container Cloud Service.

## Getting Started

First, clone this repository, and change into the directory containing this README file.

### Login to Docker Hub
You will be building Docker images and pushing them to Docker Hub. In order to push to Docker Hub, you will need to authenticate with Docker Hub. Open a terminal and login to Docker Hub with this command:

```
docker login
```

You will then be prompted for your username and password. Enter your Docker Hub account name (which is NOT your email address). You can find this by logging in to Docker Hub in a Web browser and finding the name next to your avatar in the top navigation of the Docker Hub Web site.

```
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username:
Password:
Login Succeeded
```

Now that you have logged into Docker Hub in your terminal, change into the `stacks` directory and read the `README.md` document to buid your stacks.

### Configure the Builder to Use Your Docker Hub Account

Before you can build your first stack, open [images/build/vars.mk](images/build/vars.mk) and set the registry name variable as your Docker Hub account (usernames should be entered in lower case):

```
REGISTRY_NAME ?= your_docker_hub_username
```

### Build all the Stacks at once - Preferred Method

Within the `stacks` directory run the make command:

```
make
```

This will sequentially build all the dependencies and stacks at once and push the images into repos in your Docker Hub account.

### Build an individual Stack - Optional Method

If you only want to build an individual stack, for example, the load balancing with HAProxy stack (HAProxy and NGINX), two dependent images need to be built first: runit and confd.

Open a terminal and execute the following commands from the main directory (the one containing `stacks` and `images`:

```
cd images/runit
make
cd ../confd
make
cd ../../stacks/haproxy-lb-to-nginx
make
```

### Run the Stack in Container Cloud Service

Now that your Stacks are built, you have a `stack.yml` file in the `haproxy-lb-to-nginx` directory. Let's use that `stack.yml` file to run the `haproxy-lb-to-nginx` example stack.

In Container Cloud Service, create a new stack.

* Click on "Stacks" in the left navigation
* Click the "New Stack" button
* Enter `haproxy-lb-to-nginx` in the "Stack Name" field
* Click the "Advanced Editor" link on the "New Stack" page
* Return to your terminal and get the stack YML:

```
cat stack.yml
```

* Copy and paste the contents of `stack.yml` into the advanced editor
* Click the "Done" button
* Click the "Save" button

Your stack is defined, now go deploy the stack!

* Click the "Deploy" button in the "haproxy-lb-to-nginx" row in the stacks list
* Enter `3` in the "Quantity" field of the "Orchestration for backend" section
* Click the "Deploy" button

Container Cloud Service will pull the images from your Docker Hub account and launch them in the cluster.

After deploying your stack and the healthchecks all pass, you'll need to figure out which host your HAProxy container is running on.

* In the "loadbalancer" section of the "Containers" tab on your deployment's page, identify the name of the "Hostname"
* Click on the Hostname
* Find the Public IP address on the Host details page
* Point your browser to http://PUBLIC_IP:8886 (replace PUBLIC_IP with the IP address of your host). Port 8886 is the HAProxy port defined in your stack YML

## Additional Information

### Stacks

Stacks are composed of images. The stack definition is a YML file, much like a Docker Compose file, which lists the services that make up a stack. For each of the services, environment variables can be set and injected into running containers when the stack is deployed.

For example, a stack may consist of a load balancer and some upstream, or backend web or application servers. Or, a logging stack may consist of a database, a log aggregator, and a visualizer.

The `stacks` directory contains a directory for each of the stacks. For each stack, a `Makefile` and YML template is included. The `Makefile` is used to build all the images required by the stack and generate (from the template file) a YML file which can be copied and pasted into the advanced stack editor of the Container Cloud Service.

The directory listing below shows the files used to create the `haproxy-lb-to-nginx` stack.

```
haproxy-lb-to-nginx
├── Makefile
└── stack.template.yml
```

### Images

Images are the building blocks of stacks. Images are pulled from a registry and launched as containers with the necessary configuration.

The images used by the stacks in this repository are found in the `images` directory. Each image has its own directory, and contains the `Dockerfile` and supporting files for that image. For example, the `haproxy` image directory contains the following files:

```
haproxy
├── Dockerfile
├── Makefile
├── README.md
├── haproxy.cfg.stub
├── haproxy.cfg.template_orig
├── haproxy.sh
└── haproxy.toml.template
```

To build an image, use the `Makefile` included in that image's directory (or just build it manually using `docker build ...`):

```
make image
```
