#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

import os
import socket

# Variables
# =========
# Environment Vars
hostname       = socket.gethostname()
# Admin Vars
admin_name     = os.environ.get('ADMIN_NAME', 'AdminServer')
admin_username = os.environ.get('ADMIN_USERNAME', 'weblogic')
admin_password = "ADMIN_PASSWORD"
admin_host     = os.environ.get('ADMIN_HOST', 'wlsadmin')
admin_port     = os.environ.get('ADMIN_PORT', '7001')

# Node Manager Vars
nmname         = os.environ.get('NM_NAME', 'Machine-' + hostname)

print('node manager name : [%s]' % nmname);
print('admin port        : [%s]' % admin_port);
print('admin host        : [%s]' % admin_host);
print('admin password    : [%s]' % admin_password);
print('admin name        : [%s]' % admin_name);
print('admin username    : [%s]' % admin_username);
print('hostname          : [%s]' % hostname);
print('nmname            : [%s]' % nmname);

# Functions
def editMode():
    edit()
    startEdit(waitTimeInMillis=-1, exclusive="true")

def saveActivate():
    save()
    activate(block="true")

def connectToAdmin():
    connect(admin_username, admin_password, url='t3://' + admin_host + ':' + admin_port, adminServerName=admin_name)
