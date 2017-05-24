# Rolling Deployment Router Image with sticky sessions

## Purpose

This image is a specialized load balancer for doing [rolling, or canary deployments](http://martinfowler.com/bliki/CanaryRelease.html).

This is an extended version of <a href="https://github.com/oracle/docker-images/tree/master/ContainerCloud/images/rolling-router">the original image</a> that supports session affinity. The sticky sessions module used is <a href="https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng">nginx-sticky-module-ng</a>.

Besides the the Nginx module above this version adds a new key value <a href="https://github.com/mikarinneoracle/docker-images/blob/master/ContainerCloud/images/rolling-router/deploy_keyvalues.sh#L23">stickyness</a> and based on the value, either 0 or 1:

<ol>
<li>First call from a client is load balanced based on <a href="https://github.com/mikarinneoracle/docker-images/blob/master/ContainerCloud/images/rolling-router/deploy_keyvalues.sh#L19">blendpercent</a> e.g. 10% (90/10 split)</li>
<li>Subsequent calls from a client are balanced depending on stickiness.<br>
If set to 1, then session affinity i.e. stickyness, if set to 0, then based on blendpercent e.g. 10% (90/10 split)</li>
</ol>

## Overview

The rolling router image is built on confd to dynamically derive the backend services and create NGINX upstreams to those services. See the [confd image documentation](../confd/README.md) for more details about that image.

The container uses confd to check every 5 seconds for new services using a given service key. When confd sees a change, it rewrites the nginx.conf file and reloads the NGINX service.

## Prerequisites

### Variables

The router image needs the following environment variables:

* `KV_IP` - the IP address which provides the key/value endpoint, when using this image with a stack the docker0 IP address can be used, e.g. 172.17.0.1
* `KV_PORT` - the port on which the key/value endpoint is listening, when using this image with a stack, `9109` should be used
* `OCCS_API_TOKEN` - the token used to authenticate with the key/value store endpoint; when using this image with a stack the value can be derived with `{{api_token}}`
* `APP_NAME` - an arbitrary value that points to a key in the key value store's `rolling/*` namespace

### Service Discovery Keys

Four service discovery keys are required for this implementation:

* `rolling/null` - this key is used as an empty placeholder for defaults
* `rolling/APP_NAME/stable/id` - the service discovery ID used to derive the running containers for the stable backend
  * default to `rolling/null` when creating the key
  * value will be set to `apps/app-${APP_NAME}-${TIMESTAMP}-${EXPOSED_PORT}/containers` in operation
* `rolling/APP_NAME/candidate/id` - the service discovery ID used to derive the running containers for the candidate backend
  * default to `rolling/null` when creating the key
  * value will be set to `apps/app-${APP_NAME}-${TIMESTAMP}-${EXPOSED_PORT}/containers` in operation
* `rolling/APP_NAME/blendpercent` - an integer in the range 0..100 representing the percent of traffic to send to the candidate version
  * default to `0` when creating the key
  * value will be set manually by a user to control the percentage of requests sent to the candidate version, e.g. 10, 30, 60, 100
* `rolling/APP_NAME/stickyness` - an integer either 1 or 0 representing the true or false of session stickyness
  * default to `0` when creating the key
  * value will be set manually by a user to control the session stickyness, e.g. 0 or 1

## Configuration

The router configuration is based on NGINX. The NGINX configuration files need to dynamically change when containers are deployed in OCCS. Confd provides the mechanism to watch service discovery keys in OCCS and generate dynamic configuraiton files for NGINX.

### Management UI in port 8080

Router configuration can also done via an interactive management UI.

The management UI listens on port 8080 in the container. When running the container, map some port, e.g. 8080, to port 8080 in the container.

### Virtual Host

The [nginx-files/99-app](./nginx-files/99-app) file defines the virtual host that will proxy to the backend services.

### Upstream

An upstream file will be generated and written to `/etc/nginx/sites-enabled/00-upstream-blue` when Confd finds new backend services in OCCS. The detection mechanism hinges on the presence of certain service discovery keys. Generating the upstream file is a two-step process with Confd.

The [nginx-files/00-upstream-placeholder](./nginx-files/00-upstream-placeholder) file defines a placeholder configuration file that will setup the upstream services until Confd can generate a new upstream file.

First, because Confd doesn't allow for dynamic key watching, we have to use Confd to generate additional Confd files and inject the variables needed to discover the backend services.

* [confd-files/00-upstream.toml.toml](./confd-files/00-upstream.toml.toml) uses [confd-files/00-upstream.toml.template](./confd-files/00-upstream.toml.template) to generate a Confd template resource at `/etc/confd/conf.d/00-upstream.toml`
* [confd-files/00-upstream.template.toml](./confd-files/00-upstream.template.toml) uses [confd-files/00-upstream.template.template](./confd-files/00-upstream.template.template) to generate a Confd template at `/etc/confd/templates/00-upstream.template`

Second, Confd automatically uses the generated files to generate a new file. The generated `/etc/confd/conf.d/00-upstream-blue.toml` template resource uses the generated `/etc/confd/templates/00-upstream-blue.template` template to generate a shell script, `/tmp/00-upstream.sh`. The `reload_cmd` is set to execute the generated shell script. The shell script is required to do arithmetic to determine the NGINX weighting for upstream servers (Confd templates do not support arithmetic out-of-the-box). The shell script will generate the `/etc/nginx/sites-enabled/00-upstream` NGINX configuration file, test the NGINX configuration, and reload NGINX.

## Usage

NGINX's frontend listens on port 80 in the container. When running the container, map some port, e.g. 8000, to port 80 in the container.

Once the image is up and running, you can then access the frontend by navigating to http://mgr:8000 (where *mgr* is the host or IP address of the host running your router container, and port 8000 is the host port mapped to port 80 in the container).

The management UI listens on port 8080 in the container. When running the container, map some port, e.g. 8080, to port 8080 in the container.

Once the image is up and running, you can then access the management UI by navigating to http://mgr:8080 (where *mgr* is the host or IP address of the host running your router container, and port 8080 is the host port mapped to port 8080 in the container).
