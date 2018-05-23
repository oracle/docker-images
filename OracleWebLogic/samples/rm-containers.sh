#!/bin/bash
#
# Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
