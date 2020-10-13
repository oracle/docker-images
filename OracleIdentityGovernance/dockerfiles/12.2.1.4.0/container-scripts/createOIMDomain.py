# # Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
# #
# # Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# #
# # Author: OIM Development (<raminder.deep.kaler@oracle.com>)
# #
import os
import sys
import com.oracle.cie.domain.script.jython.WLSTException as WLSTException

class OIMProvisioner:

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

    OIM_CLUSTERS = {
        'oim_cluster' : {}
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

    OIM_SERVERS = {
        'oim_server1' : {
            'ListenAddress': '',
            'ListenPort': 14001,
            'Machine': 'machine1',
            'Cluster': 'oim_cluster'
        }
    }

    def __init__(self, oracleHome, javaHome, domainParentDir):
        self.oracleHome = self.validateDirectory(oracleHome)
        self.javaHome = self.validateDirectory(javaHome)
        self.domainParentDir = self.validateDirectory(domainParentDir, create=True)
        return

    def createOimDomain(self, name, user, password, db, dbPrefix, dbPassword, domainType, hostName):
        domainHome = self.createBaseDomain(name, user, password, domainType)
        self.extendOimDomain(domainHome, db, dbPrefix, dbPassword, user, password, hostName)

    def createBaseDomain(self, name, user, password,domainType):
        selectTemplate('Basic WebLogic Server Domain')
        loadTemplates()
        showTemplates()
        setOption('DomainName', name)
        setOption('JavaHome', self.javaHome)
        setOption('ServerStartMode', 'prod')
        set('Name', domainName)
        cd('/Security/' + domainName + '/User/weblogic')
        set('Name', user)
        set('Password', password)

        print 'Creating Node Managers...'
        for machine in self.MACHINES:
            cd('/')
            create(machine, 'Machine')
            cd('Machine/' + machine)
            create(machine, 'NodeManager')
            cd('NodeManager/' + machine)
            for param in self.MACHINES[machine]:
                set(param, self.MACHINES[machine][param])

        print 'Creating Admin server...'
        for server in self.SERVERS:
            cd('/')
            if server == 'AdminServer':
                cd('Server/' + server)
                for param in self.SERVERS[server]:
                    set(param, self.SERVERS[server][param])
                    continue
        setOption('OverwriteDomain', 'true')
        domainHome = self.domainParentDir + '/' + name
        print 'Writing base domain...'
        writeDomain(domainHome)
        closeTemplate()
        print 'Base domain created at ' + domainHome
        return domainHome

    def extendOimDomain(self, domainHome, db, dbPrefix, dbPassword, user, password, hostName):
        print 'Extending domain at ' + domainHome
        fmwDb = 'jdbc:oracle:thin:@' + db
        readDomain(domainHome)
        selectTemplate('Oracle Identity Manager')
        loadTemplates()
        showTemplates()

        cd('/JdbcSystemResource/opss-data-source/JdbcResource/opss-data-source/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_OPSS')

        cd('/JdbcSystemResource/opss-audit-DBDS/JdbcResource/opss-audit-DBDS/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_IAU_APPEND')

        cd('/JdbcSystemResource/opss-audit-viewDS/JdbcResource/opss-audit-viewDS/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_IAU_VIEWER')

        # Config WSM
        cd('/JdbcSystemResource/mds-soa/JdbcResource/mds-soa/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_MDS')

        # Config SOA
        cd('/Server/soa_server1')
        cmo.setListenPort(8001)

        # Database configuration for SOA
        cd('/JdbcSystemResource/OraSDPMDataSource/JdbcResource/OraSDPMDataSource/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.xa.client.OracleXADataSource')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_UMS')

        cd('/JdbcSystemResource/mds-owsm/JdbcResource/mds-owsm/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_MDS')

        cd('/JdbcSystemResource/SOADataSource/JdbcResource/SOADataSource/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.xa.client.OracleXADataSource')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_SOAINFRA')

        cd('/JdbcSystemResource/SOALocalTxDataSource/JdbcResource/SOALocalTxDataSource/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_SOAINFRA')

        cd('/JdbcSystemResource/EDNDataSource/JdbcResource/EDNDataSource/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.xa.client.OracleXADataSource')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_SOAINFRA')

        cd('/JdbcSystemResource/EDNLocalTxDataSource/JdbcResource/EDNLocalTxDataSource/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_SOAINFRA')

        cd('/JdbcSystemResource/mds-soa/JdbcResource/mds-soa/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_MDS')

        cd('/JdbcSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_STB')

        cd('/JdbcSystemResource/oimOperationsDB/JdbcResource/oimOperationsDB/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.xa.client.OracleXADataSource')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_OIM')

        cd('/JdbcSystemResource/soaOIMLookupDB/JdbcResource/soaOIMLookupDB/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        set('PasswordEncrypted', dbPassword)
        cmo.setDriverName('oracle.jdbc.xa.client.OracleXADataSource')
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_OIM')

        cd('/JdbcSystemResource/mds-oim/JdbcResource/mds-oim/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_MDS')

        cd('/JdbcSystemResource/oimJMSStoreDS/JdbcResource/oimJMSStoreDS/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_OIM')

        cd('/JdbcSystemResource/ApplicationDB/JdbcResource/ApplicationDB/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_OIM')

        cd('/JdbcSystemResource/soaOIMLookupDB/JdbcResource/soaOIMLookupDB/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.xa.client.OracleXADataSource')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_OIM')

        cd('/JdbcSystemResource/opss-data-source')
        set("Target","AdminServer,oim_server1,soa_server1")
        cd('/JdbcSystemResource/opss-audit-DBDS')
        set("Target","AdminServer,oim_server1,soa_server1")
        cd('/JdbcSystemResource/opss-audit-viewDS')
        set("Target","AdminServer,oim_server1,soa_server1")
        cd('/JDBCSystemResource/oimOperationsDB')
        set("Target","oim_server1,soa_server1")

        cd('/JdbcSystemResource/WLSSchemaDataSource/JdbcResource/WLSSchemaDataSource/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_WLS')

        cd('/')
        cd('Credential/TargetStore/oim')
        cd('TargetKey/keystore')
        create('c','Credential')
        cd('Credential')
        set('Username','keystore')
        set('Password',password)

        cd('/')
        cd('Credential/TargetStore/oim')
        cd('TargetKey/OIMSchemaPassword')
        create('c','Credential')
        cd('Credential')
        set('Username',dbPrefix + '_OIM')
        set('Password',dbPassword)

        cd('/')
        cd('Credential/TargetStore/oim')
        cd('TargetKey/sysadmin')
        create('c','Credential')
        cd('Credential')
        set('Username','xelsysadm')
        set('Password',password)

        cd('/')
        cd('Credential/TargetStore/oim')
        cd('TargetKey/WeblogicAdminKey')
        create('c','Credential')
        cd('Credential')
        set('Username',user)
        set('Password',password)

        cd('/')
        cd('/Server/AdminServer')
        cmo.setListenAddress('oimadmin')

        cd('/')
        cd('/Server/oim_server1')
        cmo.setListenAddress('oimms')


        cd('/')
        cd('/Server/soa_server1')
        cmo.setListenAddress('soams')

        self.enable_admin_channel('oim_server1', hostName,14002)
        self.enable_admin_channel('soa_server1', hostName,8003)
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


    def enable_admin_channel(self, server_name, channel_address, channel_port):
        print('setting server t3channel for server ' + server_name)
        cd('/Servers/' + server_name)
        create('T3Channel', 'NetworkAccessPoint')
        cd('/Servers/' + server_name + '/NetworkAccessPoint/T3Channel')
        set('ListenPort', int(channel_port))
        set('PublicPort', int(channel_port))
        set('PublicAddress', channel_address)
        print('t3 channel created for server: ' + server_name + 'for address: ' + channel_address )


#############################
# Entry point to the script #
#############################

def usage():
    print sys.argv[0] + ' -oh <oracle_home> -jh <java_home> -parent <domain_parent_dir> [-name <domain-name>] ' + \
          '[-user <domain-user>] [-password <domain-password>] ' + \
          '-rcuDb <rcu-database> [-rcuPrefix <rcu-prefix>] [-rcuSchemaPwd <rcu-schema-password>] ' + \
          '-domainType <soa|osb|bpm|soaosb> '
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

provisioner = OIMProvisioner(oracleHome, javaHome, domainParentDir)
provisioner.createOimDomain(domainName, domainUser, domainPassword, rcuDb, rcuSchemaPrefix, rcuSchemaPassword,domainType, hostName)

