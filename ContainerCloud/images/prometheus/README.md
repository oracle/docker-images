# Prometheus Image

## Purpose

This repo allows for the immediate and simple use of the Prometheus monitoring tool. This tool monitors container and machine activity across multiple hosts.

# Overview

This image allows you to monitor any number of docker hosts and their containers using Google's `cAdvisor` and Soundcloud's `Prometheus.`

The Prometheus configuration is extremely simple so as to offer very little opinion on how a user would run the Prometheus service itself. For information on configuring Prometheus to meet _your_ needs, please see [the 
documentation](http://prometheus.io/docs/operating/configuration/).

Adding a new host to your mesh will result in `cAdvisor` starting on that host and registering itself with Prometheus (using confd and service discovery).

Scale without headache.

## Prerequisites

The Prometheus image needs the following environment variables (for confd to derive the backend cAdvisor containers):

* `KV_IP` - the IP address which provides the key/value endpoint, when using this image with a stack the docker0 IP address can be used, e.g. 172.17.0.1
* `KV_PORT` - the port on which the key/value endpoint is listening, when using this image with a stack, `9109` should be used
* `OCCS_API_TOKEN` - the token used to authenticate with the key/value store endpoint; when using this image with a stack the value can be derived with `{{api_token}}`
* `OCCS_BACKEND_KEY` - the key prefix in the key/value store for the backend services; when using this image with a stack the value can be derived with `{{sd_deployment_containers_path "backend" 80}}` (where "backend" is the name of the backend services in the stack YML)

## Configuration

Backend cAdvisor containers are derived using the key prefix defined in `OCCS_BACKEND_KEY`. Confd watches that key prefix (in the format `apps/APP_NAME/containers`) in order to generate the `prometheus.yml` file.

Consider your `OCCS_BACKEND_KEY` is `apps/myapp/containers` and examine this snippet from `/etc/confd/templates/prometheus.yml.template`:

```
- job_name: prometheus-scraper
  scrape_interval: 5s
  target_groups:
    - targets: [
    {{range gets "/apps/myapp/containers/*"}}
    '{{.Value}}',{{end}}
    ]
```

Define the following key/value pairs in Container Cloud Service (when deploying a stack, this is done automatically for you):

```
apps/myapp/containers/one=10.9.1.1:32001
apps/myapp/containers/two=10.9.1.2:32002
```

Confd will pick up the changes to the key prefix (`apps/myapp/containers`) and update `prometheus.yml`. Here is a snippet of the generated file:

```
- job_name: prometheus-scraper
  scrape_interval: 5s
  target_groups:
    - targets: [
    '10.9.1.1:32001',
    '10.9.1.2:32002',
    ]
```

## Usage

Prometheus's frontend listens on port 9090 in the container. When running the container, map some port, e.g. 9090, to port 9090 in the container.

Once Prometheus is up and running, you can then access the frontend by navigating to http://mesh-host:9090 (where *mesh-host* is the host or IP address of the host running your Prometheus container, and port 9090 is the host port mapped to port 9090 in the container).
