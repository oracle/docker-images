# Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
##
# WLST Online for deploying a Data Source
# It will read the domain under DOMAIN_HOME by default
#
# author: Monica Riccelli <monica.riccelli@oracle.com>
# since: December, 2017
from java.io import FileInputStream
import java.lang
import os
import string


print('***Starting WLST Online Configure DS***');

#Read Properties
##############################

# 1 - Connecting details - read from system arguments
##############################
domainname = os.environ.get('DOMAIN_NAME', 'base_domain')
admin_name = os.environ.get('ADMIN_NAME', 'AdminServer')
domainhome = os.environ.get('DOMAIN_HOME', '/u01/oracle/user_projects/domains/' + domainname)
adminport = os.environ.get('ADMIN_PORT', '7001')
username = os.environ.get('ADMIN_USER', 'weblogic')
password = os.environ.get('ADMIN_PASSWORD', 'welcome1')
admin_url='t3://localhost:7001'

print('admin_name  : [%s]' % admin_name);
print('admin_user  : [%s]' % username);
print('admin_password  : [%s]' % password);
print('admin_port  : [%s]' % adminport);
print('domain_home  : [%s]' % domainhome);
print('dsname  : [%s]' % dsname);
print('admin_url  : [%s]' % admin_url);
print('target_type  : [%s]' % target_type);

# Connect to the AdminServer.
connect(username, password, "t3://localhost:7001")

edit()
startEdit()

# Create Datasource
# ==================
print 'Create Data Source'
cd('/')
cmo.createJDBCSystemResource(dsname)

cd('/JDBCSystemResources/' + dsname + '/JDBCResource/' + dsname)
cmo.setName(dsname)

cd('/JDBCSystemResources/' + dsname + '/JDBCResource/' + dsname + '/JDBCDataSourceParams/' + dsname)
set('JNDINames',jarray.array([String(dsjndiname)], String))

cd('/JDBCSystemResources/' + dsname + '/JDBCResource/' + dsname + '/JDBCDriverParams/' + dsname)
cmo.setUrl(dsurl)
cmo.setDriverName(dsdriver)
set('Password', dspassword)

cd('/JDBCSystemResources/' + dsname + '/JDBCResource/' + dsname + '/JDBCConnectionPoolParams/' + dsname)
cmo.setTestTableName('SQL SELECT 1 FROM DUAL\r\n\r\n')
cmo.setInitialCapacity(int(cp_initial_capacity))

cd('/JDBCSystemResources/' + dsname + '/JDBCResource/' + dsname + '/JDBCDriverParams/' + dsname + '/Properties/' + dsname)
cmo.createProperty('user')

cd('/JDBCSystemResources/' + dsname + '/JDBCResource/' + dsname + '/JDBCDriverParams/' + dsname + '/Properties/' + dsname + '/Properties/user')
cmo.setValue(dsusername)

cd('/JDBCSystemResources/' + dsname + '/JDBCResource/' + dsname + '/JDBCDataSourceParams/' + dsname)
cmo.setGlobalTransactionsProtocol('TwoPhaseCommit')

activate()

print 'Targeting DS to the AdminServer'

startEdit()
cd ('/JDBCSystemResources/'+ dsname)
set('Targets',jarray.array([ObjectName('com.bea:Name='+admin_name+',Type='+target_type)], ObjectName))

activate()
# Update Domain, Close It, Exit
# ==========================

disconnect()
exit()
print('***End of  WLST Online Configure DS***');
