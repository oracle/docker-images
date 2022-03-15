#!/bin/bash
# 
# Since: March, 2022
# Author: abhishek.by.kumar@oracle.com
# Description: Donwloads required packages and latest APEX zip, for installing APEX with ORDS.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 
# Copyright (c) 2014-2022 Oracle and/or its affiliates. All rights reserved.
# 

yum -y install oracle-instantclient-release-el7 && \
yum -y install oracle-instantclient-sqlplus.x86_64 tar && \
curl https://download.oracle.com/otn_software/apex/apex-latest.zip -o "${ORDS_HOME}"/config/ords/apex-latest.zip && \
rm -rf /var/cache/yum && \
rm -rf /var/tmp/yum-*
