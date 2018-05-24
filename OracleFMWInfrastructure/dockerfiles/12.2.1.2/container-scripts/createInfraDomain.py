# Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

import os
import sys

import com.oracle.cie.domain.script.jython.WLSTException as WLSTException

class Infra12212Provisioner:

    MACHINES = {
        'machine1' : {
            'NMType': 'SSL',
            'ListenAddress': 'localhost',
            'ListenPort': 5658
        }
    }

    CLUSTERS = {
        'infra_cluster' : {}
    }

    SERVERS = {
        'AdminServer' : {
            'ListenAddress': '',
            'ListenPort': 7001,
            'Machine': 'machine1'
        },
        'infra_server1' : {
            'ListenAddress': '',
            'ListenPort': 8001,
            'Machine': 'machine1',
            'Cluster': 'infra_cluster'
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

    def __init__(self, oracleHome, javaHome, domainParentDir):
        self.oracleHome = self.validateDirectory(oracleHome)
        self.javaHome = self.validateDirectory(javaHome)
        self.domainParentDir = self.validateDirectory(domainParentDir, create=True)
        return

    def createInfraDomain(self, name, user, password, db, dbPrefix, dbPassword):
        domainHome = self.createBaseDomain(name, user, password)
        self.extendDomain(domainHome, db, dbPrefix, dbPassword)

    def createBaseDomain(self, name, user, password):
        baseTemplate = self.replaceTokens(self.JRF_12212_TEMPLATES['baseTemplate'])

        readTemplate(baseTemplate)
        setOption('DomainName', name)
        setOption('JavaHome', self.javaHome)
        setOption('ServerStartMode', 'prod')
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
                continue
            create(server, 'Server')
            cd('Server/' + server)
            for param in self.SERVERS[server]:
                set(param, self.SERVERS[server][param])

        setOption('OverwriteDomain', 'true')
        domainHome = self.domainParentDir + '/' + name

        print 'Writing base domain...'
        writeDomain(domainHome)
        closeTemplate()
        print 'Base domain created at ' + domainHome
        return domainHome


    def extendDomain(self, domainHome, db, dbPrefix, dbPassword):
        print 'Extending domain at ' + domainHome
        readDomain(domainHome)
        setOption('AppDir', self.domainParentDir + '/applications')

        print 'Applying JRF templates...'
        for extensionTemplate in self.JRF_12212_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))

        print 'Extension Templates added'

        print 'Configuring the Service Table DataSource...'
        fmwDb = 'jdbc:oracle:thin:@' + db
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
        serverGroupsToTarget = list(self.JRF_12212_TEMPLATES['serverGroupsToTarget'])
        cd('/')
        for server in self.SERVERS:
            if not server == 'AdminServer':
                setServerGroups(server, serverGroupsToTarget)
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
          '-rcuDb <rcu-database> [-rcuPrefix <rcu-prefix>] [-rcuSchemaPwd <rcu-schema-password>]'
    sys.exit(0)


print str(sys.argv[0]) + " called with the following sys.argv array:"
for index, arg in enumerate(sys.argv):
    print "sys.argv[" + str(index) + "] = " + str(sys.argv[index])

if len(sys.argv) < 6:
    usage()

#oracleHome will be passed by command line parameter -oh.
oracleHome = None
#javaHome will be passed by command line parameter -jh.
javaHome = None
#domainParentDir will be passed by command line parameter -parent.
domainParentDir = None
#domainUser is hard-coded to weblogic. You can change to other name of your choice. Command line paramter -user.
domainUser = 'weblogic'
#domainPassword will be passed by Command line parameter -password.
#domainPassword = 'welcome1'
domainPassword = None
#rcuDb will be passed by command line parameter -rcuDb.
rcuDb = None
#change rcuSchemaPrefix to your infra schema prefix. Command line parameter -rcuPrefix.
rcuSchemaPrefix = 'DEV12'
#change rcuSchemaPassword to your infra schema password. Command line parameter -rcuSchemaPwd.
#rcuSchemaPassword = 'welcome1'
rcuSchemaPassword = None

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
    else:
        print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        usage()
        sys.exit(1)

provisioner = Infra12212Provisioner(oracleHome, javaHome, domainParentDir)
provisioner.createInfraDomain(domainName, domainUser, domainPassword, rcuDb, rcuSchemaPrefix, rcuSchemaPassword)
