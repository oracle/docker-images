#
#
# Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

import os
import sys

import com.oracle.cie.domain.script.jython.WLSTException as WLSTException

class SOA12212Provisioner:

    MACHINES = {
        'machine1' : {
            'NMType': 'SSL',
            'ListenAddress': 'localhost',
            'ListenPort': 5658
        }
    }

    SOA_CLUSTERS = {
        'soa_cluster' : {}
    }
	
    OSB_CLUSTERS = {
        'osb_cluster' : {}
    }

    SERVERS = {
        'AdminServer' : {
            'ListenAddress': '',
            'ListenPort': 7001,
            'Machine': 'machine1'
        }
         
    }
	
    SOA_SERVERS = {
        'soa_server1' : {
            'ListenAddress': '',
            'ListenPort': 8001,
            'Machine': 'machine1',
            'Cluster': 'soa_cluster'
        }         
    }	
	
    OSB_SERVERS = {
        'osb_server1' : {
            'ListenAddress': '',
            'ListenPort': 9001,
            'Machine': 'machine1',
            'Cluster': 'osb_cluster'
        }
    }  
	

    JRF_12212_TEMPLATES = {
        'baseTemplate' : '@@ORACLE_HOME@@/wlserver/common/templates/wls/wls.jar',
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.jrf_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.jrf.ws.async_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.wsmpm_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.ums_template.jar',
            '@@ORACLE_HOME@@/em/common/templates/wls/oracle.em_wls_template.jar'
        ],
        'serverGroupsToTarget' : [ 'JRF-MAN-SVR', 'WSMPM-MAN-SVR' ]
    }

    SOA_12212_TEMPLATES = {
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/soa/common/templates/wls/oracle.soa_template.jar'
        ],
        'serverGroupsToTarget' : [ 'SOA-MGD-SVRS-ONLY' ]
    }
	
    OSB_12212_TEMPLATES = {
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/osb/common/templates/wls/oracle.osb_template.jar'
        ],
        'serverGroupsToTarget' : [ 'OSB-MGD-SVRS-ONLY' ]
    }

    BPM_12212_TEMPLATES = {
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/soa/common/templates/wls/oracle.bpm_template.jar'
        ],
        'serverGroupsToTarget' : [ 'SOA-MGD-SVRS-ONLY' ]
    }
	
    def __init__(self, oracleHome, javaHome, domainParentDir):
        self.oracleHome = self.validateDirectory(oracleHome)
        self.javaHome = self.validateDirectory(javaHome)
        self.domainParentDir = self.validateDirectory(domainParentDir, create=True)
        return

    def configureXADataSources(self):
        cd('/JDBCSystemResources/SOADataSource/JdbcResource/SOADataSource')
	cd('JDBCDriverParams/NO_NAME_0')
        set('DriverName', 'oracle.jdbc.xa.client.OracleXADataSource')
        cd('/JDBCSystemResources/EDNDataSource/JdbcResource/EDNDataSource')
	cd('JDBCDriverParams/NO_NAME_0')
        set('DriverName', 'oracle.jdbc.xa.client.OracleXADataSource')
        cd('/JDBCSystemResources/OraSDPMDataSource/JdbcResource/OraSDPMDataSource')
	cd('JDBCDriverParams/NO_NAME_0')
        set('DriverName', 'oracle.jdbc.xa.client.OracleXADataSource')
        return

    def createDomain(self, name, user, password, db, dbPrefix, dbPassword,domainType):
        domainHome = self.createBaseDomain(name, user, password,domainType)
        
        if domainType == "soa" or domainType == "soaosb":
		self.extendSoaDomain(domainHome, db, dbPrefix, dbPassword)
	
        if domainType == "osb" or domainType == "soaosb" :	
		self.extendOsbDomain(domainHome, db, dbPrefix, dbPassword,domainType)  
		
        if domainType == "bpm":
		self.extendBpmDomain(domainHome, db, dbPrefix, dbPassword)
	

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

        if domainType == "soa" or domainType == "bpm" or domainType == "soaosb":	
		for cluster in self.SOA_CLUSTERS:
			cd('/')
			create(cluster, 'Cluster')
			cd('Cluster/' + cluster)
			for param in  self.SOA_CLUSTERS[cluster]:
				set(param, self.SOA_CLUSTERS[cluster][param])
				
		for server in self.SOA_SERVERS:
			cd('/')
			create(server, 'Server')
			cd('Server/' + server)
			for param in self.SOA_SERVERS[server]:
				set(param, self.SOA_SERVERS[server][param])
		
		print 'INFO: SOA Servers created.....' 

        if domainType == 'osb' or domainType == "soaosb":
		
		print 'INFO: Creating OSB cluster...'
		for cluster in self.OSB_CLUSTERS:
			cd('/')
			create(cluster, 'Cluster')
			cd('Cluster/' + cluster)
			for param in  self.OSB_CLUSTERS[cluster]:
				set(param, self.OSB_CLUSTERS[cluster][param])
		
		for server in self.OSB_SERVERS:
			cd('/')
			create(server, 'Server')
			cd('Server/' + server)
			for param in self.OSB_SERVERS[server]:
				set(param, self.OSB_SERVERS[server][param])


	        print 'INFO: OSB Servers created.....' 				
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

    def applySOATemplates(self):
        print 'INFO: Applying SOA templates...'
        for extensionTemplate in self.SOA_12212_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))
        return
		
    def configureJDBCTemplates(self,db,dbPrefix,dbPassword):	
        print 'INFO: Configuring the Service Table DataSource...'
        fmwDb = 'jdbc:oracle:thin:@' + db
        cd('/JDBCSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource')
        cd('JDBCDriverParams/NO_NAME_0')
        set('DriverName', 'oracle.jdbc.OracleDriver')
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)

        stbUser = dbPrefix + '_STB'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', stbUser)

        print 'INFO: Getting Database Defaults...'
        getDatabaseDefaults()
        return

    def targetSOAServers(self,serverGroupsToTarget):    
        for server in self.SOA_SERVERS:
            if not server == 'AdminServer':
                setServerGroups(server, serverGroupsToTarget)
                print "INFO: Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:" + server
                cd('/Servers/' + server)
                set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    def targetSOACluster(self):
        for cluster in self.SOA_CLUSTERS:
            print "INFO: Set CoherenceClusterSystemResource to defaultCoherenceCluster for cluster:" + cluster
            cd('/Cluster/' + cluster)
            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return


    def targetOSBServers(self,serverGroupsToTarget):    
        for server in self.OSB_SERVERS:
            if not server == 'AdminServer':
                setServerGroups(server, serverGroupsToTarget)
                print "INFO: Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:" + server
                cd('/Servers/' + server)
                set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    def targetOSBCluster(self):
        for cluster in self.OSB_CLUSTERS:
            print "INFO: Set CoherenceClusterSystemResource to defaultCoherenceCluster for cluster:" + cluster
            cd('/Cluster/' + cluster)
            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    def extendSoaDomain(self, domainHome, db, dbPrefix, dbPassword):
	self.readAndApplyJRFTemplates(domainHome)
	self.applySOATemplates()
        
        print 'INFO: Extension Templates added'
	
	self.configureJDBCTemplates(db,dbPrefix,dbPassword)
	self.configureXADataSources()
	
        print 'INFO: Targeting Server Groups...'
        serverGroupsToTarget = list(self.JRF_12212_TEMPLATES['serverGroupsToTarget'])
        serverGroupsToTarget.extend(self.SOA_12212_TEMPLATES['serverGroupsToTarget'])

        cd('/')
        self.targetSOAServers(serverGroupsToTarget)

        cd('/')
        self.targetSOACluster()
        
        print "INFO: Set WLS clusters as target of defaultCoherenceCluster:[" + ",".join(self.SOA_CLUSTERS) + "]"

        cd('/CoherenceClusterSystemResource/defaultCoherenceCluster')
        set('Target', ",".join(self.SOA_CLUSTERS))		 
        print 'INFO: Preparing to update domain...'
        updateDomain()
        print 'INFO: Domain updated successfully'
        closeDomain()
        return


    def extendOsbDomain(self, domainHome, db, dbPrefix, dbPassword,domainType):
	self.readAndApplyJRFTemplates(domainHome)
			
        print 'INFO: Applying OSB templates...'
        for extensionTemplate in self.OSB_12212_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))

        print 'INFO: Extension Templates added'

	self.configureJDBCTemplates(db,dbPrefix,dbPassword)
        cd('/JDBCSystemResources/SOADataSource/JdbcResource/SOADataSource')
        cd('JDBCDriverParams/NO_NAME_0')
        set('DriverName', 'oracle.jdbc.xa.client.OracleXADataSource')
        cd('/JDBCSystemResources/OraSDPMDataSource/JdbcResource/OraSDPMDataSource')
        cd('JDBCDriverParams/NO_NAME_0')
        set('DriverName', 'oracle.jdbc.xa.client.OracleXADataSource')
 
	
        print 'INFO: Targeting Server Groups...'
        serverGroupsToTarget = list(self.JRF_12212_TEMPLATES['serverGroupsToTarget'])
        serverGroupsToTarget.extend(self.OSB_12212_TEMPLATES['serverGroupsToTarget'])

        cd('/')
        self.targetOSBServers(serverGroupsToTarget)

        cd('/')
        self.targetOSBCluster()
        
        print "INFO: Set WLS clusters as target of defaultCoherenceCluster:[" + ",".join(self.OSB_CLUSTERS) + "]"
        cd('/CoherenceClusterSystemResource/defaultCoherenceCluster')
        set('Target', ",".join(self.OSB_CLUSTERS))
		 
        print 'INFO: Preparing to update domain...'
        updateDomain()
        print 'INFO: Domain updated successfully'
        closeDomain()
        return


    def extendBpmDomain(self, domainHome, db, dbPrefix, dbPassword):
	self.readAndApplyJRFTemplates(domainHome)

        print 'INFO: Applying BPM templates...'
        for extensionTemplate in self.BPM_12212_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))
		
        print 'INFO: Extension Templates added'

	self.configureJDBCTemplates(db,dbPrefix,dbPassword)
	self.configureXADataSources()
	
        print 'INFO: Targeting Server Groups...'
        serverGroupsToTarget = list(self.JRF_12212_TEMPLATES['serverGroupsToTarget'])
        serverGroupsToTarget.extend(self.BPM_12212_TEMPLATES['serverGroupsToTarget'])

        cd('/')
        self.targetSOAServers(serverGroupsToTarget)

        cd('/')
        self.targetSOACluster()
        
        print "INFO: Set WLS clusters as target of defaultCoherenceCluster:[" + ",".join(self.SOA_CLUSTERS) + "]"

        cd('/CoherenceClusterSystemResource/defaultCoherenceCluster')
        set('Target', ",".join(self.SOA_CLUSTERS))		 
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

def usage():
    print sys.argv[0] + ' -oh <oracle_home> -jh <java_home> -parent <domain_parent_dir> [-name <domain-name>] ' + \
          '[-user <domain-user>] [-password <domain-password>] ' + \
          '-rcuDb <rcu-database> [-rcuPrefix <rcu-prefix>] [-rcuSchemaPwd <rcu-schema-password>] ' + \
          '-domainType <soa|osb|bpm|soaosb> ' 
    sys.exit(0)


print "createDomain.py called with the following inputs:"
for index, arg in enumerate(sys.argv):
    print "INFO: sys.argv[" + str(index) + "] = " + str(sys.argv[index])

if len(sys.argv) < 6:
    usage()

#oracleHome will be passed by command line parameter -oh.
oracleHome = None
#javaHome will be passed by command line parameter -jh.
javaHome = None
#domainParentDir will be passed by command line parameter -parent.
domainParentDir = None
#domainName is hard-coded to soa_domain. You can change to other name of your choice. Command line parameter -name.
domainName = 'soa_domain'
#domainUser is hard-coded to weblogic. You can change to other name of your choice. Command line paramter -user.
domainUser = 'weblogic'
#domainPassword is hard-coded to welcome1. You can change to other password of your choice. Command line parameter -password.
domainPassword = 'welcome1'
#rcuDb will be passed by command line parameter -rcuDb.
rcuDb = None
#change rcuSchemaPrefix to your soainfra schema prefix. Command line parameter -rcuPrefix.
rcuSchemaPrefix = 'DEV12'
#change rcuSchemaPassword to your soainfra schema password. Command line parameter -rcuSchemaPwd.
rcuSchemaPassword = 'welcome1'

i = 1
while i < len(sys.argv):
    if sys.argv[i] == '-oh':
        oracleHome = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-jh':
        javaHome = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-parent':
        domainParentDir = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-name':
        domainName = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-user':
        domainUser = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-password':
        domainPassword = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-rcuDb':
        rcuDb = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-rcuPrefix':
        rcuSchemaPrefix = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-rcuSchemaPwd':
        rcuSchemaPassword = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-domainType':
        domainType = sys.argv[i + 1]
        i += 2	
    else:
        print 'INFO: Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        usage()
        sys.exit(1)
		

provisioner = SOA12212Provisioner(oracleHome, javaHome, domainParentDir)
provisioner.createDomain(domainName, domainUser, domainPassword, rcuDb, rcuSchemaPrefix, rcuSchemaPassword,domainType)
