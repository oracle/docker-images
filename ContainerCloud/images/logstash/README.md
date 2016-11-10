# Logstash Image

## Purpose

This repo contains the artifacts necessary to build a logstash docker image.

## Inputs

This image exposes port 5000 (tcp and udp) for inputs into the logstash pipeline.

## Outputs

In addition to a `stdout` output, logstash sends events to an elasticsearch instance at the `elasticsearch` DNS host. When this image is launched, the `elasticsearch` host must be passed in via link or additional DNS.
