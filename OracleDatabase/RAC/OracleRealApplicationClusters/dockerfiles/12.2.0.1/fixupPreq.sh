#!/usr/bin/env bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Setup the Linux kernel parameter inside the container. Note that some parameter need to be set on Docker host.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

rpm -Uvh "$GRID_HOME/cv/rpm/cvuqdisk*"
echo "oracle   soft   nofile    1024" > /etc/security/limits.conf
echo "oracle   hard   nofile    65536" >> /etc/security/limits.conf
echo "oracle   soft   nproc    16384" >> /etc/security/limits.conf
echo "oracle   hard   nproc    16384" >> /etc/security/limits.conf
echo "oracle   soft   stack    10240" >> /etc/security/limits.conf
echo "oracle   hard   stack    32768" >> /etc/security/limits.conf
echo "oracle   hard   memlock    134217728" >> /etc/security/limits.conf
echo "oracle   soft   memlock    134217728" >> /etc/security/limits.conf
echo "grid   soft   nofile    1024" >> /etc/security/limits.conf
echo "grid   hard   nofile    65536" >> /etc/security/limits.conf
echo "grid   soft   nproc    16384" >> /etc/security/limits.conf
echo "grid   hard   nproc    16384" >> /etc/security/limits.conf
echo "grid   soft   stack    10240" >> /etc/security/limits.conf
echo "grid   hard   stack    32768" >> /etc/security/limits.conf
echo "grid   hard   memlock    134217728" >> /etc/security/limits.conf
echo "grid   soft   memlock    134217728" >> /etc/security/limits.conf
echo "ulimit -S -s 10240" >> /home/grid/.bashrc
echo "ulimit -S -s 10240" >> /home/oracle/.bashrc
