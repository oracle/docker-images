#!/usr/bin/python
# Copyright (c) 2020,2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
import os
import sys

import com.oracle.cie.domain.script.jython.WLSTException as WLSTException

class WCPortal12214Provisioner:

    MACHINES = {
        'machine1' : {
            'NMType': 'SSL',
            'ListenAddress': 'localhost',
            'ListenPort': 5556
        }
    }

    CLUSTERS = {
        'wcportal_cluster1' : {},
        'wcportlet_cluster1' : {}
    }

    SERVERS = {
        'AdminServer' : {
            'ListenAddress': '',
            'ListenPort': 7001,
            'Machine': 'machine1'
        },
        'WC_Portal' : {
            'ListenAddress': '',
            'ListenPort': 8888,
            'Machine': 'machine1',
            'Cluster': 'wcportal_cluster1'
        },
        'WC_Portlet' : {
            'ListenAddress': '',
            'ListenPort': 7777,
            'Machine': 'machine1',
            'Cluster': 'wcportlet_cluster1'
        }
    }

    JRF_12214_TEMPLATES = {
        'baseTemplate' : '@@ORACLE_HOME@@/wlserver/common/templates/wls/wls.jar',
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.jrf_template.jar' ,
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.wsmpm_template.jar',
            '@@ORACLE_HOME@@/em/common/templates/wls/oracle.em_wls_template.jar'
        ],
        'serverGroupsToTarget' : [ 'JRF-MAN-SVR', 'WSMPM-MAN-SVR' ]
    }

    WCPortal_12214_TEMPLATES = {
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/wcportal/common/templates/wls/oracle.wc_spaces_template.jar',
            '@@ORACLE_HOME@@/wcportal/common/templates/wls/oracle.analyticscollector_template.jar'
        ],
        'serverGroupsToTarget' : [ 'AS-MGD-SVRS_SPACES-MGD-SVRS' ]
    }
    WCPortlet_12214_TEMPLATES = {
            'extensionTemplates' : [
                '@@ORACLE_HOME@@/wcportal/common/templates/wls/oracle.portlet_producer_apps_template.jar',
                '@@ORACLE_HOME@@/wcportal/common/templates/wls/oracle.ootb_producers_template.jar'
            ],
            'serverGroupsToTarget' : [ 'ENSEMBLE-MGD-SVRS_PRODUCER_APPS-MGD-SVRS' ]
        }
    def __init__(self, oracleHome, javaHome, domainParentDir, adminServerPort, managedServerPort, managedServerPortletPort):
        self.oracleHome = self.validateDirectory(oracleHome)
        self.javaHome = self.validateDirectory(javaHome)
        self.domainParentDir = self.validateDirectory(domainParentDir, create=True)
        self.SERVERS['AdminServer']['ListenPort'] = int(adminServerPort)
        self.SERVERS['WC_Portal']['ListenPort'] = int(managedServerPort)
        self.SERVERS['WC_Portlet']['ListenPort'] = int(managedServerPortletPort)
        return

    def createWCPortalDomain(self, name, user, password, db, dbPrefix, dbPassword):
        domainHome = self.createBaseDomain(name, user, password)
        self.extendDomain(domainHome, db, dbPrefix, dbPassword)

    def createBaseDomain(self, name, user, password):
        baseTemplate = self.replaceTokens(self.JRF_12214_TEMPLATES['baseTemplate'])
        readTemplate(baseTemplate)
        setOption('DomainName', name)
        setOption('JavaHome', self.javaHome)
        set('Name', domainName)
        cd('/Security/' + domainName + '/User/weblogic')
        set('Name', user)
        set('Password', password)

        print 'Creating cluster...'
        for cluster in self.CLUSTERS:
            cd('/')
            create(cluster, 'Cluster')
            cd('Cluster/' + cluster)
            for param in  self.CLUSTERS[cluster]:
                set(param, self.CLUSTERS[cluster][param])
       
        print 'Creating Node Managers...'
        for machine in self.MACHINES:
            cd('/')
            create(machine, 'Machine')
            cd('Machine/' + machine)
            create(machine, 'NodeManager')
            cd('NodeManager/' + machine)
            for param in self.MACHINES[machine]:
                set(param, self.MACHINES[machine][param])

        print 'Creating Servers...'
        for server in self.SERVERS:
            cd('/')
            if server == 'AdminServer':
                cd('Server/' + server)
                for param in self.SERVERS[server]:
                    set(param, self.SERVERS[server][param])
                    print 'assigning ' + param + ' to ' + server + ':'
                    print self.SERVERS[server][param] 
                continue
            create(server, 'Server')
            cd('Server/' + server)
            for param in self.SERVERS[server]:
                set(param, self.SERVERS[server][param])
                print 'assigning ' + param + ' to ' + server + ':'
                print self.SERVERS[server][param]

        setOption('OverwriteDomain', 'true')
        setOption('ServerStartMode', 'prod')
        domainHome = self.domainParentDir + '/' + name
       
        print 'Writing base domain...'
        writeDomain(domainHome)
        closeTemplate()

        print 'Base domain created at ' + domainHome
        return domainHome


    def extendDomain(self, domainHome, db, dbPrefix, dbPassword):
        print 'Extending domain at ' + domainHome
        readDomain(domainHome)

        print 'Applying JRF templates...'
        for extensionTemplate in self.JRF_12214_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))

        print 'Applying WCPortal templates...'
        for extensionTemplate in self.WCPortal_12214_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))

        print 'Applying WCPortlet templates...'
        for extensionTemplate in self.WCPortlet_12214_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))
        print 'Extension Templates added'

        print 'Configuring the Service Table DataSource...'
        fmwDb = 'jdbc:oracle:thin:@' + db

        print "fmwDb = " + fmwDb
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

        print 'Targeting Server Groups...'
        serverGroupsToTarget = list(self.JRF_12214_TEMPLATES['serverGroupsToTarget'])
        serverGroupsToTarget.extend(self.WCPortal_12214_TEMPLATES['serverGroupsToTarget'])

        cd('/')
        for server in self.SERVERS:
            if not server == 'AdminServer':
                print "Overriding WCPortal templates default values :" + server
                cd('/Servers/' + server)
                for param in self.SERVERS[server]:
                    set(param, self.SERVERS[server][param])
                    print 'assigning ' + param + ' to ' + server + ':'
                    print self.SERVERS[server][param]            
                
        cd('/')
        for server in self.SERVERS:
            if not server == 'AdminServer':
                print "Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:" + server
                cd('/Servers/' + server)
                set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
               
        cd('/')
        for cluster in self.CLUSTERS:
            print "Set CoherenceClusterSystemResource to defaultCoherenceCluster for cluster:" + cluster
            cd('/Cluster/' + cluster)
            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')

        print "Set WLS clusters as target of defaultCoherenceCluster:[" + ",".join(self.CLUSTERS) + "]"
        cd('/CoherenceClusterSystemResource/defaultCoherenceCluster')
        set('Target', ",".join(self.CLUSTERS))

        cd('/AppDeployments/wsm-pm')
        set('Targets', ",".join(('AdminServer', 'WC_Portal' ,'WC_Portlet')))
        
        print 'Preparing to update domain... '
        updateDomain()

        print 'Domain updated successfully.'
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
    print sys.argv[0] + sys.argv[1] + ' -oh <oracle_home> -jh <java_home> -parent <domain_parent_dir> [-name <domain-name>] ' + \
          '[-user <domain-user>] [-password <domain-password>] ' + \
          '-rcuDb <rcu-database> [-rcuPrefix <rcu-prefix>] [-rcuSchemaPwd <rcu-schema-password>]' + \
          '[-adminServerPort <admin-port>] [-managedServerPort <wcportal_port>]'
    sys.exit(0)

if len(sys.argv) < 6:
    usage()

#oracleHome will be passed by command line parameter -oh.
oracleHome = None

#javaHome will be passed by command line parameter -jh.
javaHome = None

#domainParentDir will be passed by command line parameter -parent.
domainParentDir = None

#domainName is hard-coded to wc_domain. You can change to other name of your choice. Command line parameter -name.
domainName = 'wc_domain'

#domainUser will be passed by command line parameter -domainUser.
domainUser = None 

#domainPassword will be passed by command line parameter -domainPassword.
domainPassword = None

#rcuDb will be passed by command line parameter -rcuDb.
rcuDb = None

#rcuSchemaPrefix will be passed by command line parameter -rcuSchemaPrefix.
rcuSchemaPrefix = None

#rcuSchemaPassword will be passed by command line parameter -rcuSchemaPassword.
rcuSchemaPassword = None

#adminServerPort is hard-coded 7001.You can change to other name of your choice. Command line parameter -adminServerPort.
adminServerPort = '7001'

#managedServerPort is hard-coded 8888.You can change to other name of your choice. Command line parameter -managedServerPort.
managedServerPort = '8888'

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
    elif sys.argv[i] == '-adminServerPort':
        adminServerPort = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-managedServerPort':
        managedServerPort = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-managedServerPortletPort':
         managedServerPortletPort = sys.argv[i + 1]
         i += 2
    else:
        print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        usage()
        sys.exit(1)

provisioner = WCPortal12214Provisioner(oracleHome, javaHome, domainParentDir, adminServerPort, managedServerPort, managedServerPortletPort)
provisioner.createWCPortalDomain(domainName, domainUser, domainPassword, rcuDb, rcuSchemaPrefix, rcuSchemaPassword)

