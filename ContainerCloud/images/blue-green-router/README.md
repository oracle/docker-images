# Blue/Green Router Image

## Purpose

This image is a specialized load balancer for doing [blue/green deployments](http://martinfowler.com/bliki/BlueGreenDeployment.html).

## Overview

The blue/gren router image is built on confd to dynamically derive the backend services and create NGINX upstreams to those services. See the [confd image documentation](../confd/README.md) for more details about that image.

The container uses confd to check every 5 seconds for new services using a given service key. When confd sees a change, it rewrites the nginx.conf file and reloads the NGINX service.

## Prerequisites

### Variables

The router image needs the following environment variables:

* `KV_IP` - the IP address which provides the key/value endpoint, when using this image with a stack the docker0 IP address can be used, e.g. 172.17.0.1
* `KV_PORT` - the port on which the key/value endpoint is listening, when using this image with a stack, `9109` should be used
* `OCCS_API_TOKEN` - the token used to authenticate with the key/value store endpoint; when using this image with a stack the value can be derived with `{{api_token}}`
* `APP_NAME` - an arbitrary value that points to a key in the key value store's `blue-green/*` namespace

### Service Discovery Keys

Four service discovery keys are required for the blue/green implementation:

* blue-green/null - this key is used as an empty placeholder for defaults
* blue-green/APP_NAME/current - the current color being served by the router
  * must be blue or green in operation
  * default to green when creating the key
  * replace APP_NAME with the value of the corresponding environment variable described above
* blue-green/APP_NAME/blue/id - the service discovery ID used to derive the running containers for the blue backend
  * default to blue-green/null when creating the key
  * replace APP_NAME with the value of the corresponding environment variable described above
* blue-green/APP_NAME/green/id - the service discovery ID used to derive the running containers for the green backend
  * default to blue-green/null when creating the key
  * replace APP_NAME with the value of the corresponding environment variable described above

## Configuration

The router configuration is based on NGINX. The NGINX configuration files need to dynamically change when containers are deployed in OCCS. Confd provides the mechanism to watch service discovery keys in OCCS and generate dynamic configuraiton files for NGINX.

### Virtual Host

The [confd-files/99-app.template](./confd-files/99-app.template) file defines the virtual host that will proxy to the backend services. Confd will watch a key, e.g. `blue-green/APP_NAME/current`, and generate the virtual host file when that key's value changes. The generated file will be written to `/etc/nginx/sites-enabled/99-app` and NGINX will reload its configuration.

### Blue Upstream

An upstream file will be generated and written to `/etc/nginx/sites-enabled/00-upstream-blue` when Confd finds new backend services in OCCS. The detection mechanism hinges on the presence of certain service discovery keys. Generating the upstream file is a two-step process with Confd.

First, because Confd doesn't allow for dynamic key watching, we have to use Confd to generate additional Confd files and inject the variables needed to discover the backend services.

* [confd-files/00-upstream-blue.toml.toml](./confd-files/00-upstream-blue.toml.toml) uses [confd-files/00-upstream-blue.toml.template](./confd-files/00-upstream-blue.toml.template) to generate a Confd template resource at `/etc/confd/conf.d/00-upstream-blue.toml`
* [confd-files/00-upstream-blue.template.toml](./confd-files/00-upstream-blue.template.toml) uses [confd-files/00-upstream-blue.template.template](./confd-files/00-upstream-blue.template.template) to generate a Confd template at `/etc/confd/templates/00-upstream-blue.template`

Second, Confd automatically uses the generated files to generate a new file. The generated `/etc/confd/conf.d/00-upstream-blue.toml` template resource uses the generated `/etc/confd/templates/00-upstream-blue.template` template to generate `/etc/nginx/sites-enabled/00-upstream-blue` NGINX configuration file. The upstream file knows how to find the backend services from the OCCS service discovery key that gets injected into the templates.

### Green Upstream

The proces to generate the green upstream file is identical to the process described above for generating the blue upstream file.

## Usage

NGINX's frontend listens on port 80 in the container. When running the container, map some port, e.g. 8000, to port 80 in the container.

Once the image is up and running, you can then access the frontend by navigating to http://mgr:8000 (where *mgr* is the host or IP address of the host running your router container, and port 8000 is the host port mapped to port 80 in the container).
