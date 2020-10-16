# Apache Backend Image

## Purpose

This image is used to demonstrate how Apache httpd server can be a backend for a load balancer. It serves up a single HTML page that shows the hostname of the container.

# Prerequisites

To use a pre-built docker image available (on the Container Cloud Service hosts) as part of a stack, add `OCCS_PULL_ON_CREATE=false` as an environment variable. This is helpful in development when building the docker image on the mesh leader.

## Usage

Start the container and publish port 80 to some port on the host.

```
docker run -d -p :80 occs/apache-backend
```

Find the dynamic port on the host which the container's port 80 is published to:

```
docker ps
# b139cd126fb7        occs/apache-backend   "/start.sh"         5 seconds ago       Up 4 minutes        443/tcp, 0.0.0.0:32790->80/tcp   angry_leakey`
```

When curling the address, the response will include the `$HOSTNAME` from the container in the HTML:

```
curl http://localhost:32790
# <h1>b139cd126fb7</h1>
```

By returning the container's `$HOSTNAME`, you will easily be able to tell which backend responded in a multicontainer setup.
