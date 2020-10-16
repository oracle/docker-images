# This makefile is included by the makefiles in each of the stack directories.
# Each stack's makefile must declare the following variables:
#
# REGISTRY_NAME: the name of the docker repo for that image
# IMAGES:        a space-delimited list of the dependent image directories
#                found in ../images

SHELL=/bin/bash

images:
	for i in $(IMAGES); do \
	  pushd ../../images/$$i && \
	  make image publish && \
	  popd; \
	done

generate-stack-yml:
	sed \
	  -e "s/__REGISTRY_NAME__/${REGISTRY_NAME}/g" \
	  -e "s/__VERSION_APACHE_BACKEND__/${VERSION_APACHE_BACKEND}/g" \
	  -e "s/__VERSION_CONFD__/${VERSION_CONFD}/g" \
	  -e "s/__VERSION_HAPROXY__/${VERSION_HAPROXY}/g" \
	  -e "s/__VERSION_KIBANA__/${VERSION_KIBANA}/g" \
	  -e "s/__VERSION_LOGSPOUT__/${VERSION_LOGSPOUT}/g" \
	  -e "s/__VERSION_LOGSTASH__/${VERSION_LOGSTASH}/g" \
	  -e "s/__VERSION_NGINX_BACKEND__/${VERSION_NGINX_BACKEND}/g" \
	  -e "s/__VERSION_NGINX_LB__/${VERSION_NGINX_LB}/g" \
	  -e "s/__VERSION_PROMETHEUS__/${VERSION_PROMETHEUS}/g" \
	  -e "s/__VERSION_RUNIT__/${VERSION_RUNIT}/g" \
	  stack.template.yml > stack.yml

.PHONY: stack images publish generate-stack-yml

.DEFAULT_GOAL := stack
stack: images generate-stack-yml

