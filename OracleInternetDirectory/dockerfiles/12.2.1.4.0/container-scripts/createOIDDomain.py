# Copyright (c) 2021, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: Pratyush Dash
#
import os
import sys
import com.oracle.cie.domain.script.jython.WLSTException as WLSTException

class OIDProvisioner:

    MACHINES = {
        'oidhost1' : {
            'NMType': 'SSL',
            'ListenAddress': 'localhost',
            'ListenPort': 5556
        }
    }
    OID_CLUSTERS = {
        'oid_cluster' : {}
    }

    SERVERS = {
        'AdminServer' : {
            'ListenAddress': '',
            'ListenPort': 7001,
            'Machine': 'oidhost1'
        }

    }

    def __init__(self, oracleHome, javaHome, domainParentDir):
        self.oracleHome = self.validateDirectory(oracleHome)
        self.javaHome = self.validateDirectory(javaHome)
        self.domainParentDir = self.validateDirectory(domainParentDir, create=True)
        return

    def createOidDomain(self, name, user, password, db, dbPrefix, dbPassword, domainType, hostName):
        domainHome = self.createBaseDomain(name, user, password, domainType)
        self.extendOidDomain(domainHome, db, dbPrefix, dbPassword, user, password, hostName)

    def createBaseDomain(self, name, user, password, domainType):
        setTopologyProfile('Expanded')
        selectTemplate('Basic WebLogic Server Domain')
        loadTemplates()
        showTemplates()
        setOption('DomainName', name)
        setOption('JavaHome', self.javaHome)
        setOption('ServerStartMode', 'prod')
        set('Name', domainName)
        #cd('/Security/' + domainName + '/User/weblogic')
        #set('Name', user)
        #set('Password', password)
        cd('/')
        create('sc', 'SecurityConfiguration')
        cd('SecurityConfiguration/sc')
        set('NodeManagerUsername', user)
        set('NodeManagerPasswordEncrypted', password)
        setOption('NodeManagerType','PerDomainNodeManager')
        print 'Creating Node Managers...'
        for machine in self.MACHINES:
            print('Machine is = ', machine)
            cd('/')
            create(machine, 'Machine')
            cd('Machine/' + machine)
            create(machine, 'NodeManager')
            #cd('NodeManager/' + machine)
            cd('/Machines/' + machine + '/NodeManager/' + machine)
            ls
            for param in self.MACHINES[machine]:
                print('Param is = ', param)
                print('Value is = ',self.MACHINES[machine][param])
                set(param, self.MACHINES[machine][param])

        print 'Creating Admin server...'
        for server in self.SERVERS:
            cd('/')
            if server == 'AdminServer':
                cd('Server/' + server)
                for param in self.SERVERS[server]:
                    print('Param is = ', param)
                    set(param, self.SERVERS[server][param])
                    continue
        cmo.setWeblogicPluginEnabled(true)
        cd('/Security/' + domainName + '/User/weblogic')
        set('Name', user)
        set('Password', password)
        setOption('OverwriteDomain', 'true')
        domainHome = self.domainParentDir + '/' + name
        print 'Writing base domain...'
        writeDomain(domainHome)
        closeTemplate()
        print 'Base domain created at ' + domainHome
        return domainHome

    def extendOidDomain(self, domainHome, db, dbPrefix, dbPassword, user, password, hostName):
        print 'Extending domain at ' + domainHome
        fmwDb = 'jdbc:oracle:thin:@' + db
        readDomain(domainHome)
        selectTemplate('Oracle Internet Directory ( Collocated )')
        loadTemplates()
        showTemplates()
        # Enter ODS Schema Database details
        cd('/JDBCSystemResource/oidds/JdbcResource/oidds/JdbcDriverParams/NO_NAME')
        # Enter DataBase HostName, DataBase Listen Port and Database Service Name
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('UsePasswordIndirection', 'false')
        set('UseXADataSourceInterface', 'false')
        # Enter ODS Schema Password
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue('ODS')
        cd('/JdbcSystemResource/WLSSchemaDataSource/JdbcResource/WLSSchemaDataSource/JdbcDriverParams/NO_NAME')
        # Enter DataBase HostName, DataBase Listen Port and Database Service Name
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        # Enter WLS Schema name
        cmo.setValue(dbPrefix + '_WLS')
        cd('/JdbcSystemResource/opss-data-source/JdbcResource/opss-data-source/JdbcDriverParams/NO_NAME')
        # Enter DataBase HostName, DataBase Listen Port and Database Service Name
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        # Enter OPSS Schema Password
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        # Enter OPSS Schema user
        cmo.setValue(dbPrefix + '_OPSS')
        cd('/JdbcSystemResource/opss-audit-DBDS/JdbcResource/opss-audit-DBDS/JdbcDriverParams/NO_NAME')
        # Enter DataBase HostName, DataBase Listen Port and Database Service Name
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        # Enter IAU Append Schema Password
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        # Enter IAU Append Schema name
        cmo.setValue(dbPrefix + '_IAU_APPEND')
        cd('/JdbcSystemResource/opss-audit-viewDS/JdbcResource/opss-audit-viewDS/JdbcDriverParams/NO_NAME')
        # Enter DataBase HostName, DataBase Listen Port and Database Service Name
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        # Enter IAU Viewer Schema Password
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        # Enter IAU Viewer Schema name
        cmo.setValue(dbPrefix + '_IAU_VIEWER')
        cd('/JdbcSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource/JdbcDriverParams/NO_NAME')
        # Enter DataBase HostName, DataBase Listen Port and Database Service Name
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        # Enter STB Schema Password
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        # Enter STB Schema name
        cmo.setValue(dbPrefix + '_STB')
        updateDomain()
        closeDomain()
        exit()



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
          '-domainType oim '
    sys.exit(0)

# Uncomment for debugging purposes only.
#print str(sys.argv[0]) + " called with the following sys.argv array:"
#for index, arg in enumerate(sys.argv):
#    print "sys.argv[" + str(index) + "] = " + str(sys.argv[index])

if len(sys.argv) < 6:
    usage()

#oracleHome will be passed by command line parameter -oh.
oracleHome = None
#javaHome will be passed by command line parameter -jh.
javaHome = None
#domainParentDir will be passed by command line parameter -parent.
domainParentDir = None
#domainName is hard-coded to oid_domain. You can change to other name of your choice. Command line parameter -name.
domainName = 'oid_domain'
#domainUser is hard-coded to weblogic. You can change to other name of your choice. Command line paramter -user.
domainUser = 'weblogic'
#domainPassword is hard-coded to welcome1. You can change to other password of your choice. Command line parameter -password.
domainPassword = 'welcome1'
#rcuDb will be passed by command line parameter -rcuDb.
rcuDb = None
#change rcuSchemaPrefix to your soainfra schema prefix. Command line parameter -rcuPrefix.
rcuSchemaPrefix = 'DEV1'
#change rcuSchemaPassword to your soainfra schema password. Command line parameter -rcuSchemaPwd.
rcuSchemaPassword = 'welcome1'
#change hostname to your Host's Name. Command line parameter -hostName.
hostName= 'localhost'

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
    elif sys.argv[i] == '-hostname':
        hostName = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-rcuSchemaPwd':
        rcuSchemaPassword = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-domainType':
        domainType = sys.argv[i + 1]
        i += 2
    else:
        print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        usage()
        sys.exit(1)

provisioner = OIDProvisioner(oracleHome, javaHome, domainParentDir)
provisioner.createOidDomain(domainName, domainUser, domainPassword, rcuDb, rcuSchemaPrefix, rcuSchemaPassword,domainType, hostName)
