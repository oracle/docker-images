# Kibana Image

## Purpose

This repo contains the artifacts necessary to build a kibana front end to inspect logs in an ELK stack.

## Prerequisites

This image requires an elasticsearch backend. The configuration (see `kibana.yml`) points to `http://elasticsearch:9200` as the *elasticsearch_url*. When starting this container `elasticsearch` must be resolvable by DNS either by adding a link or extra host (`--add-host=[]`).

## Usage

The kibana image exposes port 5601 for it UI. This port must be published out to a host port in order to access kibana from a browser, e.g. `5601:5601` to map the container's port to port 5601 on the host.

Once kibana is up and running you can access it by going to http://mesh-host:5601 (where *mesh-host* is the hostname or IP address of the host runnig the container and 5601 is the port number on the host).
