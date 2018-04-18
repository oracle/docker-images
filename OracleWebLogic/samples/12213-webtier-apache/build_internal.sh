#!/bin/sh

#
# Copyright (c) 2016-2018 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
docker build --build-arg http_proxy=http://www-proxy.us.oracle.com:80 \
         --build-arg https_proxy=http://www-proxy.us.oracle.com:80 \
         --build-arg no_proxy=127.0.0.1,localhost \
         -t 12213-apache .
