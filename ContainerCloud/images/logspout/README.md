# Logspout Image

## Purpose

This repo contains the artifacts necessary to build a logspout docker image. Logspout reads metrics and events from the Docker engine and publishes them to a syslog endpoint.

## Prerequisites

The logspout image needs the following environment variables:

* `KV_IP` - the IP address which provides the key/value endpoint, when using this image with a stack the docker0 IP address can be used, e.g. 172.17.0.1
* `KV_PORT` - the port on which the key/value endpoint is listening, when using this image with a stack, `9109` should be used
* `OCCS_LOGSTASH_KEY` - the key prefix in the key/value store for the logstash services; when using this image with a stack the value can be derived with `{{sd_deployment_containers_path "logstash" 5000}}` (where "logstash" is the name of the logstash services in the stack YML)

## Usage

When running the logspout container, a host volume needs to be mounted for the docker sock file. For example, run a container with:

```
docker run -e ... -v /var/run/docker.sock:/var/run/docker.sock ...
```

The entrypoint for this image is a shell script which uses the `OCCS_LOGSTASH_KEY` to look up the logstash service's IP address and port running in the cluster. Once the Ip address is found, logspout is started up pointing at the syslog listener in logstash:

```
/bin/logspout syslog://$OCCS_LOGSTASH_IP
```
