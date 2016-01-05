#!/bin/sh
# 
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
cat <<EOF >> /usr/local/apache2/conf/httpd.conf

# WebLogic Module
LoadModule weblogic_module /root/lib/${MOD_WLS_PLUGIN}

# WebLogic Configuration
<IfModule mod_weblogic.c>
  Include conf/weblogic.conf 
</IfModule>

EOF
