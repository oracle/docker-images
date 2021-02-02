# Copyright (c) 2019,2020 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: Kaushik C
#
import os
import sys

import com.oracle.cie.domain.script.jython.WLSTException as WLSTException

class OAM12214Provisioner:

    jrfDone = 0;
    MACHINES = {
        'machine1' : {
            'NMType': 'SSL',
            'ListenAddress': 'localhost',
            'ListenPort': 5557
        }
    }
    OAM_SERVERS_GRP = [ 'OAM-MGD-SVRS' ]
    POLICY_SERVERS_GRP = [ 'OAM-POLICY-MANAGED-SERVER' ]


    OAM_CLUSTERS = {
        'oam_cluster' : {}
    }

    POLICY_CLUSTERS = {
        'policy_cluster' : {}
    }


    SERVERS = {
        'AdminServer' : {
            'ListenAddress': '',
            'ListenPort': 7001
        }

    }

    OAM_SERVERS = {
        'oam_server1' : {
            'ListenAddress': '',
            'ListenPort': 14100,
            'Cluster': 'oam_cluster',
            'Machine': 'machine1'
        }
    }
    POLICY_SERVERS = {
        'oam_policy_mgr1' : {
            'ListenAddress': '',
            'ListenPort': 15100,
            'Cluster': 'policy_cluster',
            'Machine': 'machine1'
        }
    }
    
    SSL_SETTINGS = {
        'AdminServer' : {
            'Enabled': 'True',
            'ListenPort': 7002
        },
        'oam_server1' : {
            'Enabled': 'False',
            'ListenPort': 14101
        },
        'oam_policy_mgr1' : {
            'Enabled': 'False',
            'ListenPort': 15101
        }        
    }     

    WLS_BASE_TEMPLATE_NAME = 'Basic WebLogic Server Domain'
    OAM_12214_TEMPLATE_NAME = 'Oracle Access Management Suite'

    WLS_12214_TEMPLATES = {
        'baseTemplate' : '@@ORACLE_HOME@@/wlserver/common/templates/wls/wls.jar'
    }

    OAM_EXTENSION_12214_TEMPLATES = {
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.wc_skin_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.wc_composer_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.opss.rest_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.wsmjksmgmt_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.wsmagent_template.jar',
            '@@ORACLE_HOME@@/wlserver/common/templates/wls/wls_schema.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.security.sso_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.wsmpolicyattachment_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.state-management.memory-provider-template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.jrf.ws.core_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.cie.runtime_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.ums.client_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.opss_jrf_metadata_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.adf.template.jar',
            '@@ORACLE_HOME@@/wlserver/common/templates/wls/wls_coherence_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.clickhistory_template.jar',
            '@@ORACLE_HOME@@/wlserver/common/templates/wls/wls_jrf.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.jrf_base_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.jrf_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.wsm.console.core_template.jar',
            '@@ORACLE_HOME@@/em/common/templates/wls/oracle.emas_wls_template.jar',
            '@@ORACLE_HOME@@/idm/common/templates/applications/oracle.idm.common_template_12.2.2.jar',
            '@@ORACLE_HOME@@/em/common/templates/wls/oracle.em_wls_template.jar',
            '@@ORACLE_HOME@@/em/common/templates/wls/oracle.em_idm_template.jar',
            '@@ORACLE_HOME@@/idm/common/templates/applications/oracle.idm.ids.config.ui_template_12.2.2.jar',
            '@@ORACLE_HOME@@/idm/common/templates/wls/oracle.oam_12.2.2.0.0_template.jar'
        ]
    }
    
    
    def __init__(self, oracleHome, javaHome, domainParentDir):
        self.oracleHome = self.validateDirectory(oracleHome)
        self.javaHome = self.validateDirectory(javaHome)
        self.domainParentDir = self.validateDirectory(domainParentDir, create=True)
        return



    def createOAMDomain(self, domainName, user, password, db, dbPrefix, dbPassword, isSSLEnabled):
        domainHome = self.createBaseDomain(domainName, user, password, isSSLEnabled)
        self.extendOamDomain(domainHome, db, dbPrefix, dbPassword, isSSLEnabled)


    def createBaseDomain(self, domainName, user, password, isSSLEnabled):
        baseTemplate = self.replaceTokens(self.WLS_12214_TEMPLATES['baseTemplate'])
        #baseTemplate = self.replaceTokens(self.WLS_BASE_TEMPLATE_NAME)

        readTemplate(baseTemplate)
        #selectTemplate(baseTemplate)
        #loadTemplates()
        #showTemplates()
        
        setOption('DomainName', domainName)
        setOption('JavaHome', self.javaHome)
        setOption('AppDir', self.domainParentDir + '/applications')

        setOption('ServerStartMode', 'prod')
        set('Name', domainName)


        # Create Admin Server
        # =======================
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

        # Enable SSL PORT for AdminServer
        # =====================================
        if isSSLEnabled.lower() == 'true'.lower():        
          print 'INFO: Enabling SSL PORT for AdminServer...'

          for server in self.SSL_SETTINGS:
              if server == 'AdminServer':
                  cd('/Servers/' + server)
                  create(server,'SSL')
                  cd('SSL/' + server)
                  for param in self.SSL_SETTINGS[server]:
                      set(param, self.SSL_SETTINGS[server][param])
                  
                
        # cd('/Servers/AdminServer')
        # create('AdminServer','SSL')
        # cd('SSL/AdminServer')
        # set('Enabled', 'True')
        # set('ListenPort', 7002)   
        
        # Define the user password for weblogic
        # =====================================
        cd('/Security/' + domainName + '/User/weblogic')
        set('Name', user)
        set('Password', password)

        # Create a cluster
        # ======================
        for cluster in self.OAM_CLUSTERS:
            cd('/')
            create(cluster, 'Cluster')
            cd('Cluster/' + cluster)
            for param in  self.OAM_CLUSTERS[cluster]:
                set(param, self.OAM_CLUSTERS[cluster][param])

        #Create Additional cluster
        #========================
        for cluster in self.POLICY_CLUSTERS:
            cd('/')
            create(cluster, 'Cluster')
            cd('Cluster/' + cluster)
            for param in  self.POLICY_CLUSTERS[cluster]:
                set(param, self.POLICY_CLUSTERS[cluster][param])
 

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

        setOption('OverwriteDomain', 'true')
        domainHome = self.domainParentDir + '/' + domainName
        print 'Will create Base domain at ' + domainHome

        print 'Writing base domain...'
        writeDomain(domainHome)
        closeTemplate()
        print 'Base domain created at ' + domainHome
        return domainHome


    def readAndApplyExtensionTemplates(self, domainHome, db, dbPrefix, dbPassword):
        print 'Extending domain at ' + domainHome
        print 'Database  ' + db
        readDomain(domainHome)
        setOption('AppDir', self.domainParentDir + '/applications')

        self.applyExtensionTemplates()
        print 'Extension Templates added'
        return
        
    def applyExtensionTemplates(self):
        print 'Apply Extension templates'
        for extensionTemplate in self.OAM_EXTENSION_12214_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))
        return
        
    def configureJDBCTemplates(self,db,dbPrefix,dbPassword):
        print 'Configuring the Service Table DataSource...'
        fmwDb = 'jdbc:oracle:thin:@' + db
        print 'fmwDatabase  ' + fmwDb
        cd('/JDBCSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource')
        cd('JDBCDriverParams/NO_NAME_0')
        set('DriverName', 'oracle.jdbc.OracleDriver')
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)

        stbUser = dbPrefix + '_STB'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', stbUser)

        print 'Getting Database Defaults...'
        getDatabaseDefaults()
        return

    def targetManagedServers(self):
        print 'Targeting OAM Managed Server...'
        cd('/')
        for managedName in self.OAM_SERVERS:
            setServerGroups(managedName, self.OAM_SERVERS_GRP)
            cd('/Servers/' + managedName)
            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    def targetAddlManagedServers(self):
        print 'Targeting Policy Server ...'
        cd('/')
        for managedName in self.POLICY_SERVERS:
            setServerGroups(managedName, self.POLICY_SERVERS_GRP)
            cd('/Servers/' + managedName)
            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    #def targetOAMServers(self,serverGroupsToTarget):
    #    for server in self.OAM_SERVERS:
    #        if not server == 'AdminServer':
    #            setServerGroups(server, serverGroupsToTarget)
    #            print "INFO: Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:" + server
    #            cd('/Servers/' + server)
    #            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
    #    return


    #def targetPOLICYServers(self,serverGroupsToTarget):
    #    for server in self.POLICY_SERVERS:
    #        if not server == 'AdminServer':
    #            setServerGroups(server, serverGroupsToTarget)
    #            print "INFO: Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:" + server
    #            cd('/Servers/' + server)
    #            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
    #    return

        
    def targetOAMCluster(self):
        for cluster in self.OAM_CLUSTERS:
            print "INFO: Set CoherenceClusterSystemResource to defaultCoherenceCluster for cluster:" + cluster
            cd('/Cluster/' + cluster)
            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    def targetPOLICYCluster(self):
        for cluster in self.POLICY_CLUSTERS:
            print "INFO: Set CoherenceClusterSystemResource to defaultCoherenceCluster for cluster:" + cluster
            cd('/Cluster/' + cluster)
            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    def extendOamDomain(self, domainHome, db, dbPrefix, dbPassword, isSSLEnabled):
        self.readAndApplyExtensionTemplates(domainHome, db, dbPrefix, dbPassword)
        print 'Extension Templates added'

        print 'Deleting oam_server1'
        cd('/')
        delete('oam_server1', 'Server')
        print 'The default oam_server1 coming from the oam extension template deleted'
        print 'Deleting oam_policy_mgr1'
        cd('/')
        delete('oam_policy_mgr1', 'Server')
        print 'The default oam_server1 coming from the oam extension template deleted'

        print 'Configuring JDBC Templates ...'
        self.configureJDBCTemplates(db,dbPrefix,dbPassword)

        print 'Configuring Managed Servers ...'
        #ms_port    = int(managedServerPort)
        #ms_count   = int(managedCount)
        # Creating oam servers
        for server in self.OAM_SERVERS:
            cd('/')
            create(server, 'Server')
            cd('Server/' + server)
            for param in self.OAM_SERVERS[server]:
                set(param, self.OAM_SERVERS[server][param])
                
        # Enable SSL PORT for oam_server1
        # =====================================
        if isSSLEnabled.lower() == 'true'.lower():
          print 'INFO: Enabling SSL PORT for oam_server1...'            
          for server in self.SSL_SETTINGS:
              if server == 'oam_server1':
                  cd('/Servers/' + server)
                  create(server,'SSL')
                  cd('SSL/' + server)
                  for param in self.SSL_SETTINGS[server]:
                      set(param, self.SSL_SETTINGS[server][param])
            
            # cd('/Server/' + server)                
            # create(server,'SSL')
            # cd('SSL/' + server)
            # set('Enabled', 'True')
            # set('ListenPort', 14101)                

        #self.MANAGED_SERVERS = self.createManagedServers(ms_count, managedNameBase, ms_port, clusterName, self.MANAGED_SERVERS)
        # Creating policy managers
        #self.ADDL_MANAGED_SERVERS = self.createManagedServers(ms_count, self.ADDL_MANAGED_SERVER_BASENAME, self.ADDL_MANAGED_SERVER_PORT, self.ADDL_CLUSTER, self.ADDL_MANAGED_SERVERS)
        for server in self.POLICY_SERVERS:
            cd('/')
            create(server, 'Server')
            cd('Server/' + server)
            for param in self.POLICY_SERVERS[server]:
                set(param, self.POLICY_SERVERS[server][param])
                
        # Enable SSL PORT for oam_policy_mgr1
        # =====================================
        if isSSLEnabled.lower() == 'true'.lower():
          print 'INFO: Enabling SSL PORT for oam_policy_mgr1...'                            
                  
          for server in self.SSL_SETTINGS:
              if server == 'oam_policy_mgr1':
                  cd('/Servers/' + server)
                  create(server,'SSL')
                  cd('SSL/' + server)
                  for param in self.SSL_SETTINGS[server]:
                      set(param, self.SSL_SETTINGS[server][param])                

            # cd('/Server/' + server)                 
            # create(server,'SSL')
            # cd('SSL/' + server)
            # set('Enabled', 'True')
            # set('ListenPort', 15101)

        print 'Targeting Server Groups...'
        cd('/')
        self.targetManagedServers()
        self.targetAddlManagedServers()
        self.targetOAMCluster()
        self.targetPOLICYCluster()
        cd('/')


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


#############################
# Entry point to the script #
#############################

def usage():
    print sys.argv[0] + ' -oh <oracle_home> -jh <java_home> -parent <domain_parent_dir> [-name <domain-name>] ' + \
          '[-user <domain-user>] [-password <domain-password>] ' + \
          '-rcuDb <rcu-database> [-rcuPrefix <rcu-prefix>] [-rcuSchemaPwd <rcu-schema-password>] '
    sys.exit(0)


print "create_domain.py called with the following inputs:"
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
#domainName is hard-coded to oam_domain. You can change to other name of your choice. Command line parameter -name.
domainName = 'oam_domain'
#domainUser will be passed by command line parameter -user
domainUser = None
#domainPassword will be passed by command line parameter -password
domainPassword = None
#rcuDb will be passed by command line parameter -rcuDb.
rcuDb = None
#change rcuSchemaPrefix to your oaminfra schema prefix. Command line parameter -rcuPrefix.
rcuSchemaPrefix = 'OAM1'
#change rcuSchemaPassword to your oaminfra schema password. Command line parameter -rcuSchemaPwd.
rcuSchemaPassword = None
isSSLEnabled = None

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
    elif sys.argv[i] == '-isSSLEnabled':
        isSSLEnabled = sys.argv[i + 1]
        i += 2        
    else:
        print 'INFO: Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        usage()
        sys.exit(1)
provisioner = OAM12214Provisioner(oracleHome, javaHome, domainParentDir)
provisioner.createOAMDomain(domainName, domainUser, domainPassword, rcuDb, rcuSchemaPrefix, rcuSchemaPassword, isSSLEnabled)

