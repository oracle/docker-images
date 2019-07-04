#
#
# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at
# http://oss.oracle.com/licenses/upl.
#

import os
import sys

import com.oracle.cie.domain.script.jython.WLSTException as WLSTException

class WCSITES12212Provisioner:

    MACHINES = {
        '<MACHINE_NAME>' : {
            'NMType': 'SSL',
            'ListenAddress': 'localhost',
            'ListenPort': 5658
        }
    }

    WCSITES_CLUSTERS = {
        '<CLUSTER_NAME>' : {}
    }

    SERVERS = {
        'AdminServer' : {
            'ListenAddress': '',
            'ListenPort': <ADMIN_SERVER_PORT>,
            'Machine': '<MACHINE_NAME>'
        }
    }

    WCSITES_SERVERS = {
        '<SITES_SERVER_NAME>' : {
            'ListenAddress': '',
            'ListenPort': <SITES_SERVER_PORT>,
            'Machine': '<MACHINE_NAME>',
            'Cluster': '<CLUSTER_NAME>'
        }
    }

    JRF_12212_TEMPLATES = {
        'baseTemplate' : '@@ORACLE_HOME@@/wlserver/common/templates/wls/wls.jar',
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.jrf_template.jar',
            '@@ORACLE_HOME@@/em/common/templates/wls/oracle.em_wls_template.jar'
        ],
        'serverGroupsToTarget' : [ 'JRF-MAN-SVR' ]
    }

    WCSITES_12212_TEMPLATES = {
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/wcsites/common/templates/wls/oracle.wcsites.examples.template.jar'
        ],
        'serverGroupsToTarget' : [ 'WCSITES-MGD-SVR' ]
    }

    def __init__(self, oracleHome, javaHome, domainParentDir):
        self.oracleHome = self.validateDirectory(oracleHome)
        self.javaHome = self.validateDirectory(javaHome)
        self.domainParentDir = self.validateDirectory(domainParentDir, create=True)
        return

    def createDomain(self, name, user, password, db, dbPrefix, dbPassword,domainType):
        domainHome = self.createBaseDomain(name, user, password,domainType)

        if domainType == "wcsites":
                self.extendWcsitesDomain(domainHome, db, dbPrefix, dbPassword)

    def createBaseDomain(self, name, user, password,domainType):
        baseTemplate = self.replaceTokens(self.JRF_12212_TEMPLATES['baseTemplate'])

        readTemplate(baseTemplate)
        setOption('DomainName', name)
        setOption('JavaHome', self.javaHome)
        setOption('ServerStartMode', 'prod')
        set('Name', domainName)
        cd('/Security/' + domainName + '/User/weblogic')
        set('Name', user)
        set('Password', password)


        print 'INFO: Creating Node Managers...'
        for machine in self.MACHINES:
            cd('/')
            create(machine, 'Machine')
            cd('Machine/' + machine)
            create(machine, 'NodeManager')
            cd('NodeManager/' + machine)
            for param in self.MACHINES[machine]:
                set(param, self.MACHINES[machine][param])

        print 'INFO: Creating Admin server...'

        for server in self.SERVERS:
            cd('/')
            if server == 'AdminServer':
                cd('Server/' + server)
                for param in self.SERVERS[server]:
                        set(param, self.SERVERS[server][param])
                continue
            create(server, 'Server')
            cd('Server/' + server)
            for param in self.SERVERS[server]:
                set(param, self.SERVERS[server][param])

        if domainType == "wcsites":
                for cluster in self.WCSITES_CLUSTERS:
                        cd('/')
                        create(cluster, 'Cluster')
                        cd('Cluster/' + cluster)
                        for param in  self.WCSITES_CLUSTERS[cluster]:
                                set(param, self.WCSITES_CLUSTERS[cluster][param])

                for server in self.WCSITES_SERVERS:
                        cd('/')
                        create(server, 'Server')
                        cd('Server/' + server)
                        for param in self.WCSITES_SERVERS[server]:
                                set(param, self.WCSITES_SERVERS[server][param])

                print 'INFO: WCSITES Servers created.....'

        setOption('OverwriteDomain', 'true')
        domainHome = self.domainParentDir + '/' + name

        print 'INFO: Writing base domain...'
        writeDomain(domainHome)
        closeTemplate()
        print 'INFO: Base domain created at ' + domainHome
        return domainHome


    def readAndApplyJRFTemplates(self, domainHome):
        print 'INFO: Extending domain at ' + domainHome
        readDomain(domainHome)
        setOption('AppDir', self.domainParentDir + '/applications')

        print 'INFO: Applying JRF templates...'
        for extensionTemplate in self.JRF_12212_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))
        return

    def applyWCSITESTemplates(self):
        print 'INFO: Applying WCSITES templates...'
        for extensionTemplate in self.WCSITES_12212_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))
        return

    def configureJDBCTemplates(self,db,dbPrefix,dbPassword):
        print 'INFO: Configuring the Service Table DataSource...'
        fmwDb = db
        driverName = 'oracle.jdbc.OracleDriver'
        print "INFO: fmwDb..." + fmwDb
        
        cd('/JdbcSystemResource/opss-data-source/JdbcResource/opss-data-source/JdbcDriverParams/NO_NAME_0')
        set('DriverName', driverName)
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)
        
        user = dbPrefix + '_OPSS'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', user)
        
        print "INFO: Set user..." + user
        
        cd('/JdbcSystemResource/opss-audit-DBDS/JdbcResource/opss-audit-DBDS/JdbcDriverParams/NO_NAME_0')
        set('DriverName', driverName)
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)
        
        user = dbPrefix + '_IAU_APPEND'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', user)
        
        print "INFO: Set user..." + user
        
        cd('/JdbcSystemResource/opss-audit-viewDS/JdbcResource/opss-audit-viewDS/JdbcDriverParams/NO_NAME_0')
        set('DriverName', driverName)
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)
        
        user = dbPrefix + '_IAU_VIEWER'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', user)
        
        print "INFO: Set user..." + user
        
        cd('/JdbcSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource/JdbcDriverParams/NO_NAME_0')
        set('DriverName', driverName)
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)
        
        user = dbPrefix + '_STB'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', user)
        
        print "INFO: Set user..." + user
        
        cd('/JdbcSystemResource/wcsitesDS/JdbcResource/wcsitesDS/JdbcDriverParams/NO_NAME_0')
        set('DriverName', driverName)
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)
        
        user = dbPrefix + '_WCSITES'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', user)
        
        print "INFO: Set user..." + user

        print 'INFO: Getting Database Defaults...'
        getDatabaseDefaults()
        return

    def targetWCSITESServers(self,serverGroupsToTarget):
        for server in self.WCSITES_SERVERS:
            if not server == 'AdminServer':
                setServerGroups(server, serverGroupsToTarget)
                print "INFO: Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:" + server
                cd('/Servers/' + server)
                set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    def targetWCSITESCluster(self):
        for cluster in self.WCSITES_CLUSTERS:
            print "INFO: Set CoherenceClusterSystemResource to defaultCoherenceCluster for cluster:" + cluster
            cd('/Cluster/' + cluster)
            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    def extendWcsitesDomain(self, domainHome, db, dbPrefix, dbPassword):
        self.readAndApplyJRFTemplates(domainHome)
        self.applyWCSITESTemplates()

        print 'INFO: Extension Templates added'

        self.configureJDBCTemplates(db,dbPrefix,dbPassword)

        print 'INFO: Targeting Server Groups...'
        serverGroupsToTarget = list(self.JRF_12212_TEMPLATES['serverGroupsToTarget'])
        serverGroupsToTarget.extend(self.WCSITES_12212_TEMPLATES['serverGroupsToTarget'])

        cd('/')
        self.targetWCSITESServers(serverGroupsToTarget)

        cd('/')
        self.targetWCSITESCluster()

        print "INFO: Set WLS clusters as target of defaultCoherenceCluster:[" + ",".join(self.WCSITES_CLUSTERS) + "]"

        cd('/CoherenceClusterSystemResource/defaultCoherenceCluster')
        set('Target', ",".join(self.WCSITES_CLUSTERS))
        print 'INFO: Preparing to update domain...'
        updateDomain()
        print 'INFO: Domain updated successfully'
        closeDomain()
        return


 
    ###########################################################################
    # Helper Methods                                                          #
    ###########################################################################

    def validateDirectory(self, dirName, create=False):
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
        return self.fixupPath(directory)


    def fixupPath(self, path):
        result = path
        if path is not None:
            result = path.replace('\\', '/')
        return result


    def replaceTokens(self, path):
        result = path
        if path is not None:
            result = path.replace('@@ORACLE_HOME@@', oracleHome)
        return result

#############################
# Entry point to the script #
#############################

print "createDomain.py called with the following inputs:"

#oracleHome will be passed by command line parameter -oh.
oracleHome = '<ORACLE_HOME>'
#javaHome will be passed by command line parameter -jh.
javaHome = '/usr/java/default'
#domainParentDir will be passed by command line parameter -parent.
domainParentDir = '<DOMAIN_HOME>../../'
#domainName is hard-coded to wcsites_domain. You can change to other name of your choice. Command line parameter -name.
domainName = '<DOMAIN_NAME>'
#domainUser is hard-coded to weblogic. You can change to other name of your choice. Command line paramter -user.
domainUser = '<WL_USERNAME>'
#domainPassword is hard-coded to welcome1. You can change to other password of your choice. Command line parameter -password.
domainPassword = '<WL_PASSWORD>'
#rcuDb will be passed by command line parameter -rcuDb.
rcuDb = '<DB_URL>'
#change rcuSchemaPrefix to your wcsitesinfra schema prefix. Command line parameter -rcuPrefix.
rcuSchemaPrefix = '<RCU_SCHEMA_PREFIX>'
#change rcuSchemaPassword to your wcsitesinfra schema password. Command line parameter -rcuSchemaPwd.
rcuSchemaPassword = '<RCU_SCHEMA_PASSWORD>'
#change domainType to your wcsitesinfra. Command line parameter -domainType.
domainType = 'wcsites'
# Cluster Name
clusterName = '<CLUSTER_NAME>'
# Machine Name
machineName = '<MACHINE_NAME>'
# Admin Port
adminServerPort = <ADMIN_SERVER_PORT>
# Sites Port
sitesServerPort = <SITES_SERVER_PORT>
# Sites Server Name
sitesServerName = '<SITES_SERVER_NAME>'

provisioner = WCSITES12212Provisioner(oracleHome, javaHome, domainParentDir)
provisioner.createDomain(domainName, domainUser, domainPassword, rcuDb, rcuSchemaPrefix, rcuSchemaPassword,domainType)