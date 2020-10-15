# This makefile is included by the makefiles in each of the image directories.
# Each image's makefile must declare the following variables:
#
# IMG_NAME:        the name of the image inside the REGISTRY_NAME registry
# IMG_VERSION:     used as the tag for the docker image
# IMG_DIR:         the path to the directory containing the Dockerfile

image: dockerfile ## Builds the docker image
	docker build --force-rm \
	  --build-arg HTTP_PROXY=${HTTP_PROXY} \
	  --build-arg HTTPS_PROXY=${HTTP_PROXY} \
	  --build-arg http_proxy=${HTTP_PROXY} \
	  --build-arg https_proxy=${HTTP_PROXY} \
	  -t ${REGISTRY_NAME}/${IMG_NAME}:${IMG_VERSION} ${IMG_DIR}

clean: ## Removes the built docker image
	docker rmi -f ${REGISTRY_NAME}/${IMG_NAME}:${IMG_VERSION}

publish: ## Pushes the docker image to the registry
	docker push ${REGISTRY_NAME}/${IMG_NAME}:${IMG_VERSION}

dockerfile:
	if [ -e Dockerfile.template ]; then \
	  sed \
	    -e "s/__REGISTRY_NAME__/${REGISTRY_NAME}/g" \
	    -e "s/__VERSION_APACHE_BACKEND__/${VERSION_APACHE_BACKEND}/g" \
	    -e "s/__VERSION_BLUE_GREEN_ROUTER__/${VERSION_BLUE_GREEN_ROUTER}/g" \
	    -e "s/__VERSION_CONFD__/${VERSION_CONFD}/g" \
	    -e "s/__VERSION_HAPROXY__/${VERSION_HAPROXY}/g" \
	    -e "s/__VERSION_KIBANA__/${VERSION_KIBANA}/g" \
	    -e "s/__VERSION_LOGSPOUT__/${VERSION_LOGSPOUT}/g" \
	    -e "s/__VERSION_LOGSTASH__/${VERSION_LOGSTASH}/g" \
	    -e "s/__VERSION_NGINX_BACKEND__/${VERSION_NGINX_BACKEND}/g" \
	    -e "s/__VERSION_NGINX_LB__/${VERSION_NGINX_LB}/g" \
	    -e "s/__VERSION_PROMETHEUS__/${VERSION_PROMETHEUS}/g" \
	    -e "s/__VERSION_RUNIT__/${VERSION_RUNIT}/g" \
	    Dockerfile.template > Dockerfile; \
	fi;


.PHONY: image clean publish dockerfile
