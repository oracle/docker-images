# Copyright 2019, 2020 Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import os
import sys

import com.oracle.cie.domain.script.jython.WLSTException as WLSTException

class WCSITES12213Provisioner:

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

    MANAGED_SERVERS = []
    
    JRF_12213_TEMPLATES = {
        'baseTemplate' : '@@ORACLE_HOME@@/wlserver/common/templates/wls/wls.jar',
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.jrf_template.jar',
            '@@ORACLE_HOME@@/em/common/templates/wls/oracle.em_wls_template.jar'
        ],
        'serverGroupsToTarget' : [ 'JRF-MAN-SVR' ]
    }

    WCSITES_12213_TEMPLATES = {
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/wcsites/common/templates/wls/oracle.wcsites.examples.template.jar'
        ],
        'serverGroupsToTarget' : [ 'WCSITES-MGD-SVR' ]
    }

    def __init__(self, oracleHome, javaHome, domainParentDir, adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount, clusterName):
        self.oracleHome = self.validateDirectory(oracleHome)
        self.javaHome = self.validateDirectory(javaHome)
        self.domainParentDir = self.validateDirectory(domainParentDir, create=True)
        return

    def createInfraDomain(self, domainName, user, password, db, dbPrefix, dbPassword, adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount, clusterName, domainType,
                          exposeAdminT3Channel=None, t3ChannelPublicAddress=None, t3ChannelPort=None):
        domainHome = self.createBaseDomain(domainName, user, password, adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount, clusterName, domainType)
        
        if domainType == "wcsites":
                self.extendWcsitesDomain(domainHome, db, dbPrefix, dbPassword, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort)

    def createBaseDomain(self, domainName, user, password, adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount, clusterName, domainType):
        baseTemplate = self.replaceTokens(self.JRF_12213_TEMPLATES['baseTemplate'])
        
        readTemplate(baseTemplate)
        setOption('DomainName', domainName)
        setOption('JavaHome', self.javaHome)
        if (prodMode == 'true'):
            setOption('ServerStartMode', 'prod')
        else:
            setOption('ServerStartMode', 'dev')
        set('Name', domainName)
        
        admin_port = int(adminListenPort)
        ms_port    = int(managedServerPort)
        ms_count   = int(managedCount)
        
        # Create Admin Server
        # =======================
        print 'Creating Admin Server...'
        cd('/Servers/AdminServer')
        #set('ListenAddress', '%s-%s' % (domain_uid, admin_server_name_svc))
        set('ListenPort', admin_port)
        set('Name', adminName)
		
		# Define the user password for weblogic
        # =====================================
        cd('/Security/' + domainName + '/User/weblogic')
        set('Name', user)
        set('Password', password)
        
        # Create a cluster
        # ======================
        print 'Creating cluster...'
        cd('/')
        cl=create(clusterName, 'Cluster')
		
		# Create Node Manager
        # =======================
        print 'Creating Node Managers...'
        for machine in self.MACHINES:
            cd('/')
            create(machine, 'Machine')
            cd('Machine/' + machine)
            create(machine, 'NodeManager')
            cd('NodeManager/' + machine)
            for param in self.MACHINES[machine]:
                set(param, self.MACHINES[machine][param])
        # Create managed servers
        for index in range(0, ms_count):
            cd('/')
            msIndex = index+1
            cd('/')
            name = '%s%s' % (managedNameBase, msIndex)
            create(name, 'Server')
            cd('/Servers/%s/' % name )
            print('managed server name is %s' % name);
            set('ListenPort', ms_port)
            set('NumOfRetriesBeforeMSIMode', 0)
            set('RetryIntervalBeforeMSIMode', 1)
            set('Cluster', clusterName)
            set('Machine', machineName)
            self.MANAGED_SERVERS.append(name)
        print self.MANAGED_SERVERS
        
        setOption('OverwriteDomain', 'true')
        domainHome = self.domainParentDir + '/' + domainName
        print 'Will create Base domain at ' + domainHome
        
        print 'Writing base domain...'
        writeDomain(domainHome)
        closeTemplate()
        print 'Base domain created at ' + domainHome
        return domainHome

    def readAndApplyJRFTemplates(self, domainHome, db, dbPrefix, dbPassword, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort):
        print 'Extending domain at ' + domainHome
        print 'Database  ' + db
        readDomain(domainHome)
        setOption('AppDir', self.domainParentDir + '/applications')
        
        print 'ExposeAdminT3Channel %s with %s:%s ' % (exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort)
        if 'true' == exposeAdminT3Channel:
            self.enable_admin_channel(t3ChannelPublicAddress, t3ChannelPort)
        
        self.applyJRFTemplates()
        print 'Extension Templates added'
        return

    def applyJRFTemplates(self):
        print 'Applying JRF templates...'
        for extensionTemplate in self.JRF_12213_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))
        return

    def applyWCSITESTemplates(self):
        print 'Applying WCSITES templates...'
        for extensionTemplate in self.WCSITES_12213_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))
        return

    def configureJDBCTemplates(self,db,dbPrefix,dbPassword):
        print 'Configuring the Service Table DataSource...'
        fmwDb = db
        driverName = 'oracle.jdbc.OracleDriver'
        print "fmwDb..." + fmwDb
        
        cd('/JdbcSystemResource/opss-data-source/JdbcResource/opss-data-source/JdbcDriverParams/NO_NAME_0')
        set('DriverName', driverName)
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)
        
        user = dbPrefix + '_OPSS'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', user)
        
        print "Set user..." + user
        
        cd('/JdbcSystemResource/opss-audit-DBDS/JdbcResource/opss-audit-DBDS/JdbcDriverParams/NO_NAME_0')
        set('DriverName', driverName)
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)
        
        user = dbPrefix + '_IAU_APPEND'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', user)
        
        print "Set user..." + user
        
        cd('/JdbcSystemResource/opss-audit-viewDS/JdbcResource/opss-audit-viewDS/JdbcDriverParams/NO_NAME_0')
        set('DriverName', driverName)
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)
        
        user = dbPrefix + '_IAU_VIEWER'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', user)
        
        print "Set user..." + user
        
        cd('/JdbcSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource/JdbcDriverParams/NO_NAME_0')
        set('DriverName', driverName)
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)
        
        user = dbPrefix + '_STB'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', user)
        
        print "Set user..." + user
        
        cd('/JdbcSystemResource/wcsitesDS/JdbcResource/wcsitesDS/JdbcDriverParams/NO_NAME_0')
        set('DriverName', driverName)
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)
        
        user = dbPrefix + '_WCSITES'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', user)
        
        print "Set user..." + user

        print 'Getting Database Defaults...'
        getDatabaseDefaults()
        return

    def targetWCSITESServers(self,serverGroupsToTarget):
        print 'Targeting Server Groups...'
        cd('/')
        for managedName in self.MANAGED_SERVERS:
            setServerGroups(managedName, serverGroupsToTarget)
            print "Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:" + managedName
            cd('/Servers/' + managedName)
            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    def targetWCSITESCluster(self):
        print 'Targeting Cluster ...'
        cd('/')
        for cluster in self.WCSITES_CLUSTERS:
            print "Set CoherenceClusterSystemResource to defaultCoherenceCluster for cluster:" + cluster
            cd('/Cluster/' + cluster)
            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    def extendWcsitesDomain(self, domainHome, db, dbPrefix, dbPassword, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort):
        self.readAndApplyJRFTemplates(domainHome, db, dbPrefix, dbPassword, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort)
        self.applyWCSITESTemplates()
        
        print 'Extension Templates added'
        
        self.configureJDBCTemplates(db,dbPrefix,dbPassword)
        
        print 'Targeting Server Groups...'
        serverGroupsToTarget = list(self.JRF_12213_TEMPLATES['serverGroupsToTarget'])
        serverGroupsToTarget.extend(self.WCSITES_12213_TEMPLATES['serverGroupsToTarget'])
        
        cd('/')
        self.targetWCSITESServers(serverGroupsToTarget)
        
        cd('/')
        self.targetWCSITESCluster()
        
        print "Set WLS clusters as target of defaultCoherenceCluster:[" + ",".join(self.WCSITES_CLUSTERS) + "]"
        cd('/CoherenceClusterSystemResource/defaultCoherenceCluster')
        set('Target', ",".join(self.WCSITES_CLUSTERS))
        
        print 'Preparing to update domain...'
        updateDomain()
        print 'Domain updated successfully'
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

    def enable_admin_channel(self, admin_channel_address, admin_channel_port):
        if admin_channel_address == None or admin_channel_port == 'None':
            return
        cd('/')
        admin_server_name = get('AdminServerName')
        print('setting admin server t3channel for ' + admin_server_name)
        cd('/Servers/' + admin_server_name)
        create('T3Channel', 'NetworkAccessPoint')
        cd('/Servers/' + admin_server_name + '/NetworkAccessPoint/T3Channel')
        set('ListenPort', int(admin_channel_port))
        set('PublicPort', int(admin_channel_port))
        set('PublicAddress', admin_channel_address)	

#############################
# Entry point to the script #
#############################

#oracleHome will be passed by command line parameter -oh.
oracleHome = '<ORACLE_HOME>'
#javaHome will be passed by command line parameter -jh.
javaHome = '<JAVA_HOME>'
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
exposeAdminT3Channel = None
t3ChannelPort = None
t3ChannelPublicAddress = None

#change domainType to your wcsitesinfra. Command line parameter -domainType.
domainType = 'wcsites'
# Cluster Name
clusterName = '<CLUSTER_NAME>'
# Machine Name
machineName = '<MACHINE_NAME>'
# Admin Port
adminListenPort = <ADMIN_SERVER_PORT>
# Sites Port
managedServerPort = <SITES_SERVER_PORT>
# Sites Server Name
sitesServerName = '<SITES_SERVER_NAME>'
# To run in production mode set as true else false
prodMode=true

adminName='AdminServer'
managedNameBase='<SITES_SERVER_NAME>'
managedCount=1

provisioner = WCSITES12213Provisioner(oracleHome, javaHome, domainParentDir, adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount, clusterName)
provisioner.createInfraDomain(domainName, domainUser, domainPassword, rcuDb, rcuSchemaPrefix, rcuSchemaPassword, adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount, clusterName, domainType, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort)
