## NGINX Hello World Image

## Purpose

This image is used to demonstrate a simple Hello World Docker image using NGINX. It serves up a single HTML page that shows the hostname of the container.

## Usage

Start the container and publish port 80 to some port on the host.

```
REGISTRY=YOUR_DOCKER_HUB_USERNAME
docker build --rm -t ${REGISTRY}/docker-hello-world .
docker run -d -p 80 ${REGISTRY}/docker-hello-world
docker push ${REGISTRY}/docker-hello-world
```

*NOTE: Replace `YOUR_DOCKER_HUB_USERNAME` above with your own Docker Hub username.*
