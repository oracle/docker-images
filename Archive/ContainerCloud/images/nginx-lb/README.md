# NGINX Load Balancer Image

## Purpose

This image is used to demonstrate how NGINX can load balance backend Web servers.

# Overview

The NGINX load balancer image is built on confd to dynamically derive the backend web servers. See the [confd image documentation](../confd/README.md) for more details about that image.

This container is meant to balance *n* number of backend http services.

The container uses confd to check every 5 seconds for new services using a given service key. When confd sees a change, it rewrites the nginx.conf file and reloads the NGINX service.

# Prerequisites

The load balancer image needs the following environment variables:

* `KV_IP` - the IP address which provides the key/value endpoint, when using this image with a stack the docker0 IP address can be used, e.g. 172.17.0.1
* `KV_PORT` - the port on which the key/value endpoint is listening, when using this image with a stack, `9109` should be used
* `OCCS_API_TOKEN` - the token used to authenticate with the key/value store endpoint; when using this image with a stack the value can be derived with `{{api_token}}`
* `OCCS_BACKEND_KEY` - the key prefix in the key/value store for the backend services; when using this image with a stack the value can be derived with `{{sd_deployment_containers_path "backend" 80}}` (where "backend" is the name of the backend services in the stack YML)

## Configuration

Backends are derived using the key prefix defined in `OCCS_BACKEND_KEY`. Confd watches that key prefix (in the format `apps/APP_NAME/containers`) in order to generate the `nginx.conf` file.

Consider your `OCCS_BACKEND_KEY` is `apps/myapp/containers` and examine this snippet from `/etc/confd/templates/nginx.conf.template`:

```
upstream myapp1 {
    {{range gets "/apps/myapp/containers/*"}}
    server {{.Value}};{{end}}
}
```

Define the following key/value pairs in Container Cloud Service (when deploying a stack, this is done automatically for you):

```
apps/myapp/containers/one=10.9.1.1:32001
apps/myapp/containers/two=10.9.1.2:32002
```

Confd will pick up the changes to the key prefix (`apps/myapp/containers`) and update `nginx.conf`. Here is a snippet of the generated file:

```
upstream myapp1 {
    {{range gets "/apps/myapp/containers/*"}}
    server 10.9.1.1:32001;
    server 10.9.1.2:32002;
}
```

## Usage

NGINX's frontend listens on port 80 in the container. When running the container, map some port, e.g. 8000, to port 80 in the container.

Once NGINX is up and running, you can then access the frontend by navigating to http://mesh-host:8000 (where *mesh-host* is the host or IP address of the host running your NGINX container, and port 8000 is the host port mapped to port 80 in the container).

You will see a page that contains text similar to:

```
Container Hash: 0.backend.myapp-20160715-103608
```
