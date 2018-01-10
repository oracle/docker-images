# Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
import os
import sys

import com.oracle.cie.domain.script.jython.WLSTException as WLSTException


selectTemplate('Basic WebLogic Server Domain')
loadTemplates()
cd('/Security/base_domain/User/<WL_USERNAME>')
cmo.setPassword('<WL_PASSWORD>') 
cd('/Server/AdminServer')
cmo.setName('AdminServer')
cmo.setListenPort(<ADMIN_SERVER_PORT>)
cmo.setListenAddress('<SERVER_HOST>')
create('AdminServer','SSL')
cd('SSL/AdminServer')
cmo.setEnabled(true)
cmo.setListenPort(<ADMIN_SERVER_SSL_PORT>)
cmo.setHostnameVerificationIgnored(true)
cmo.setHostnameVerifier(None)
cmo.setTwoWaySSLEnabled(false)
writeDomain('<DOMAIN_HOME>')
closeTemplate()

# configure Enterprise Manager
readDomain('<DOMAIN_HOME>')
selectTemplate('Oracle Enterprise Manager')
loadTemplates() 

dbase="<DATABASE>"
# opss data sources
cd('/JdbcSystemResource/opss-data-source/JdbcResource/opss-data-source/JdbcDriverParams/NO_NAME')
cmo.setUrl('<DB_URL>')
cmo.setDriverName('<DB_DRIVER>')
set('PasswordEncrypted', '<RCU_SCHEMA_PASSWORD>')
cd('Properties/NO_NAME/Property/user')
cmo.setValue('<RCU_SCHEMA_PREFIX>_OPSS')
if dbase!="ORACLE":
	cd('../..')
	create('serverName','Property')
	cd('Property/serverName')
	cmo.setValue('<DB_HOST>')
	cd('../..')
	create('portNumber','Property')
	cd('Property/portNumber')
	cmo.setValue('<DB_PORT>')
	cd('../..')
	create('databaseName','Property')
	cd('Property/databaseName')
	cmo.setValue('<DB_SID>')

cd('/JdbcSystemResource/opss-audit-DBDS/JdbcResource/opss-audit-DBDS/JdbcDriverParams/NO_NAME')
cmo.setUrl('<DB_URL>')
cmo.setDriverName('<DB_DRIVER>')
set('PasswordEncrypted', '<RCU_SCHEMA_PASSWORD>')
cd('Properties/NO_NAME/Property/user')
cmo.setValue('<RCU_SCHEMA_PREFIX>_IAU_APPEND')
if dbase!="ORACLE":
	cd('../..')
	create('serverName','Property')
	cd('Property/serverName')
	cmo.setValue('<DB_HOST>')
	cd('../..')
	create('portNumber','Property')
	cd('Property/portNumber')
	cmo.setValue('<DB_PORT>')
	cd('../..')
	create('databaseName','Property')
	cd('Property/databaseName')
	cmo.setValue('<DB_SID>')	
	
cd('/JdbcSystemResource/opss-audit-viewDS/JdbcResource/opss-audit-viewDS/JdbcDriverParams/NO_NAME')

cmo.setUrl('<DB_URL>')
cmo.setDriverName('<DB_DRIVER>')
set('PasswordEncrypted', '<RCU_SCHEMA_PASSWORD>')
cd('Properties/NO_NAME/Property/user')
cmo.setValue('<RCU_SCHEMA_PREFIX>_IAU_VIEWER')
if dbase!="ORACLE":
	cd('../..')
	create('serverName','Property')
	cd('Property/serverName')
	cmo.setValue('<DB_HOST>')
	cd('../..')
	create('portNumber','Property')
	cd('Property/portNumber')
	cmo.setValue('<DB_PORT>')
	cd('../..')
	create('databaseName','Property')
	cd('Property/databaseName')
	cmo.setValue('<DB_SID>')	

cd('/JdbcSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource/JdbcDriverParams/NO_NAME')
cmo.setUrl('<DB_URL>')
cmo.setDriverName('<DB_DRIVER>')
set('PasswordEncrypted', '<RCU_SCHEMA_PASSWORD>')
cd('Properties/NO_NAME/Property/user')
cmo.setValue('<RCU_SCHEMA_PREFIX>_STB')
if dbase!="ORACLE":
	cd('../..')
	create('serverName','Property')
	cd('Property/serverName')
	cmo.setValue('<DB_HOST>')
	cd('../..')
	create('portNumber','Property')
	cd('Property/portNumber')
	cmo.setValue('<DB_PORT>')
	cd('../..')
	create('databaseName','Property')
	cd('Property/databaseName')
	cmo.setValue('<DB_SID>')	
	
updateDomain()
closeDomain()

# configure webcenter sites
readDomain('<DOMAIN_HOME>')
selectTemplate('<WCSITES_TEMPLATE_TYPE>') 
loadTemplates()
# change to sites server name
cd('/Server/<SITES_SERVER_NAME>')
set('Name','<SITES_SERVER_NAME>')
cmo.setListenPort(<SITES_SERVER_PORT>)
create('<SITES_SERVER_NAME>','SSL')
cd('SSL/<SITES_SERVER_NAME>')
cmo.setEnabled(true)
cmo.setListenPort(<SITES_SERVER_SSL_PORT>)
cd('/JdbcSystemResource/<SITES_DATASOURCE>/JdbcResource/<SITES_DATASOURCE>/JdbcDriverParams/NO_NAME')
cmo.setUrl('<DB_URL>')
cmo.setDriverName('<DB_DRIVER>')
set('PasswordEncrypted', '<RCU_SCHEMA_PASSWORD>')
cd('Properties/NO_NAME/Property/user')
cmo.setValue('<RCU_SCHEMA_PREFIX>_WCSITES')

updateDomain()
closeDomain()

exit()