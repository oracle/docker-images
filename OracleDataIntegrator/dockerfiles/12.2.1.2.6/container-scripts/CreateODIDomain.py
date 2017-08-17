#!/usr/bin/python
#
# Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

import os
import sys
import com.oracle.cie.domain.script.jython.WLSTException as WLSTException

#This script creates domain, extends domain with ODI Standalone Agent template
#and finally configures master and work datasources on managed server


def usage():
    print '*********USAGE*********'
    print sys.argv[0] + ' -oh <oracle_home> -jh <java_home> -parent <domain_parent_dir> -name <domain-name> ' + \
          '-rcuDb <rcu-database> -rcuPrefix <rcu-prefix> -rcuSchemaPwd <rcu-schema-password>'
    print '***********************'
    sys.exit(1)


###########################################################################
# Helper Methods                                                          #
###########################################################################

def validateDirectory(dirName, create=False):
    directory = os.path.realpath(dirName)
    if not os.path.exists(directory):
        if create:
            os.makedirs(directory)
        else:
            message = 'Directory ' + directory + ' does not exist'
            raise WLSTException(message)
    elif not os.path.isdir(directory):
        message = 'Directory ' + directory + ' is not a directory'
        raise WLSTException(message)
    return fixupPath(directory)


def fixupPath(path):
    result = path
    if path is not None:
        result = path.replace('\\', '/')
    return result


#print str(sys.argv[0]) + " called with the following sys.argv array:"
#for index, arg in enumerate(sys.argv):
#    print "sys.argv[" + str(index) + "] = " + str(sys.argv[index])

if len(sys.argv) < 17:
    usage()

i = 1
while i < len(sys.argv):
    if sys.argv[i] == '-oh':
        mw_home = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-jh':
        java_home = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-parent':
        domainParentDir = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-name':
        domainName = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-rcuDb':
        rcuDb = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-rcuPrefix':
        rcuPrefix = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-rcuSchemaPwd':
        rcuSchemaPwd = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-supervisorPwd':
        supervisorPwd = sys.argv[i + 1]
        i += 2
    else:
        print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        usage()



mw_home = validateDirectory(mw_home)
odi_home = validateDirectory(mw_home + "/odi")
domainParentDir = validateDirectory(domainParentDir, create=True)

domain_path = domainParentDir + '/' + domainName 

wls_domain_template_jar = mw_home + '/wlserver/common/templates/wls/base_standalone.jar'
odi_cam_template_jar = odi_home + '/common/templates/wls/odi_cam_unmanaged_template.jar'

#reads the template jar for domain creation
readTemplate(wls_domain_template_jar, 'Expanded')

cd(r'/Server/AdminServer')
cmo.setName('AdminServer')

writeDomain(domain_path)
closeTemplate()

#extending ODI domain with ODI Standalone Agent templates
readDomain(domain_path)
addTemplate(odi_cam_template_jar)

cd('/SecurityConfiguration/' + domainName)
cmo.setNodeManagerUsername('nodeman')
cmo.setNodeManagerPasswordEncrypted('test1234')
cmo.setUseKSSForDemo(false)
cd('/')

fmwDb = 'jdbc:oracle:thin:@' + rcuDb
stbUser = rcuPrefix + '_STB'

#Table SERVICETABLE is created in Master repository
dsname1 = "LocalSvcTblDataSource"
print 'Setting JDBCSystemResource with name '+dsname1
cd('JDBCSystemResource/'+dsname1+'/JdbcResource/'+dsname1+'/JDBCDriverParams/NO_NAME_0')
set('PasswordEncrypted', rcuSchemaPwd)
set('DriverName','oracle.jdbc.OracleDriver')
set('URL',fmwDb)
cd('Properties/NO_NAME_0/Property/user')
cmo.setValue(stbUser)


#this section extends domain with ODI templates
os.putenv("DOMAIN_HOME", domain_path)
cd('/')

odiUser = rcuPrefix + '_ODI_REPO'
dsname2 = "odiMasterRepository"
print 'Setting JDBCSystemResource with name '+dsname2
cd('/JDBCSystemResource/'+dsname2+'/JdbcResource/'+dsname2+'/JDBCDriverParams/NO_NAME_0')
set('PasswordEncrypted', rcuSchemaPwd)
set('DriverName','oracle.jdbc.OracleDriver')
set('URL',fmwDb)
cd('Properties/NO_NAME_0/Property/user')
cmo.setValue(odiUser)


cd('/')
cd('/Machine/'+"LocalODIMachine")
create("LocalODIMachine", 'NodeManager')
cd('NodeManager/'+"LocalODIMachine")
set('ListenAddress','')

# this is the instance to use for script executions
# it provides the repository connection information
# for repository-connected commands
cd('/')
instance='OracleDIAgent1'
#create(instance,"SystemComponent")
cd('/SystemComponent/'+instance)
set('ComponentType','ODI')
set('Machine','LocalODIMachine')
cd('/SystemCompConfig/OdiConfig/OdiInstance/'+instance)
set("ListenAddress",'')
set("ListenPort",'20910')
set('SupervisorUsername','SUPERVISOR')
set('PasswordEncrypted',supervisorPwd)
set('PreferredDataSource','odiMasterRepository')

print 'Done configuring the data sources'

cd('/')
servers    = cmo.getServers()
for server in servers:
    sName = server.getName()
    cd('/Servers/' + sName)
    listenAddress = cmo.getListenAddress()
    if ( listenAddress == None or listenAddress == 'All Local Addresses') :
        cmo.setListenAddress(None)

updateDomain()
closeDomain()

exit()

