# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#
# WLST Offline for deploying an application under APP_NAME packaged in APP_PKG_FILE located in APP_PKG_LOCATION
# It will read the domain under DOMAIN_HOME by default
#
# author: Bruno Borges <bruno.borges@oracle.com>
# since: December, 2015
#
import os

# Deployment Information 
domainname = os.environ.get('DOMAIN_NAME', 'base_domain')
domainhome = os.environ.get('DOMAIN_HOME', '/u01/oracle/user_projects/domains/' + domainname)

# Read Domain in Offline Mode
# ===========================
readDomain(domainhome)

# Create a JMS Server
# ===================
cd('/')
create('DockerJMSServer', 'JMSServer')

# Create a JMS System resource
# ============================
cd('/')
create('DockerJMSSystemResource', 'JMSSystemResource')
cd('JMSSystemResource/DockerJMSSystemResource/JmsResource/NO_NAME_0')

# Create a JMS Queue and its subdeployment
# ========================================
myq = create('DockerQueue','Queue')
myq.setJNDIName('jms/DockerQueue')
myq.setSubDeploymentName('DockerQueueSubDeployment')

cd('/JMSSystemResource/DockerJMSSystemResource')
create('DockerQueueSubDeployment', 'SubDeployment')

# Target resources to the servers 
# ===============================
cd('/')
assign('JMSServer', 'DockerJMSServer', 'Target', 'AdminServer')
assign('JMSSystemResource.SubDeployment', 'DockerJMSSystemResource.DockerQueueSubDeployment', 'Target', 'DockerJMSServer')

# Update Domain, Close It, Exit
# ==========================
updateDomain()
closeDomain()
exit()
