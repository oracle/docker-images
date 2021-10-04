#
# Copyright (c) 2021 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author : Avinash Yadagere <avinash.yadagere@oracle.com> , Arnab Nandi <arnab.x.nandi@oracle.com>
#

import os
import sys

import com.oracle.cie.domain.script.jython.WLSTException as WLSTException

class CreateVeridataDomain:


    BASE_TEMPLATE = '@@ORACLE_HOME@@/wlserver/common/templates/wls/wls.jar'

    VDT_TEMPLATE='@@ORACLE_HOME@@/veridata/common/templates/wls/veridata_web_template.jar'


    DB_RESOURCE_ARRAY={'VeridataDataSource':'VERIDATA',
    					'opss-audit-DBDS':'IAU_APPEND',
    					'opss-data-source':'OPSS',
    					'LocalSvcTblDataSource':'STB',
    					'opss-audit-viewDS':'IAU_VIEWER' }

    def __init__(self, oracleHome, javaHome, domainHome):
        self.oracleHome = self.validateDirectory(oracleHome)
        self.javaHome = self.validateDirectory(javaHome)
        self.domainName = self.validateDirectory(domainName,create=True)
        return



    def createDomain(self, domainName,domainPort, domainUser, domainPassword,adminPort,adminName,dbPassword,dbPrefix,dbUrl,dbDriver,prodMode):
        baseTemplate = self.replaceTokens(self.BASE_TEMPLATE)
        vdtTemplate = self.replaceTokens(self.VDT_TEMPLATE)

        readTemplate(baseTemplate)
        addTemplate(vdtTemplate)

        # Create Admin Server
        # =======================
        print 'Creating Admin Server...'
        cd('/Servers/'+adminName)
        #set('ListenAddress', '%s-%s' % (domain_uid, admin_server_name_svc))
        set('ListenPort', int(adminPort))
        #set('Name', adminName)
        setOption('ServerStartMode', prodMode)

        #setting passwords for all the components

        for dsName,ds in self.DB_RESOURCE_ARRAY.items():
            cd('/JDBCSystemResource/'+dsName+'/JdbcResource')
            cd(dsName+'/JDBCDriverParams/NO_NAME_0')
            set('DriverName', dbDriver)
            set('URL', dbUrl)
            set('PasswordEncrypted', dbPassword)
            schemaUser = dbPrefix + '_'+ds
            cd('Properties/NO_NAME_0/Property/user')
            set('Value', schemaUser)


        # Creating Veridata Domain
        # ======================================
        print 'Creating Veridata Server...'
        cd('/Servers/VERIDATA_server1')
        #set('ListenAddress', '%s-%s' % (domain_uid, admin_server_name_svc))
        set('ListenPort', int(domainPort))
        #set('Name', 'VERIDATA_server1')
        setOption('ServerStartMode', prodMode)


        # Define the user password for weblogic
        # =====================================
        cd('/Security/' + domainName + '/User/'+domainUser)
        set('Name', domainUser)
        set('Password', domainPassword)

        print 'Writing base domain...'
        writeDomain(domainHome)
        closeTemplate()
        print 'Base domain created at ' + domainHome
        return domainHome


    ###########################################################################
    # Helper Methods                                                          #
    ###########################################################################

    def validateDirectory(self, dirName, create=False,exist=True):
        directory = os.path.realpath(dirName)
        if not os.path.exists(directory):
            if create:
                os.makedirs(directory)
            elif exist:
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
    print sys.argv[0] + ' -oh <oracle_home> -jh <java_home> -dh <domain_home> [-name <domain-name>] ' + \
          '[-port <Veridata-Domain-Port>] [-user <domain-user>] [-password <domain-password>] ' + \
          '-rcuDb <rcu-database> [-rcuPrefix <rcu-prefix>] [-rcuSchemaPwd <rcu-schema-password>] ' + \
          '[-adminPort <Admin-Port>] [-adminName <Admin-Name>] [-prodMode <Prod-Name>]'
    sys.exit(0)

# Uncomment for Debug only
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
domainHome = None
#domainUser is hard-coded to weblogic. You can change to other name of your choice. Command line paramter -user.
domainUser = 'weblogic'
#domainPassword will be passed by Command line parameter -password.
#domainPassword = 'welcome1'
domainPassword = None
#dbUrl will be passed by command line parameter -rcuDb.
dbUrl = None
#dbDriver will be passed by command line parameter -rcuDb.
dbDriver = 'oracle.jdbc.OracleDriver'
#change rcuSchemaPrefix to your infra schema prefix. Command line parameter -rcuPrefix.
dbPrefix = 'DEV'
#change rcuSchemaPassword to your infra schema password. Command line parameter -rcuSchemaPwd.
#rcuSchemaPassword = 'welcome1'
dbPassword = None

i = 1
while i < len(sys.argv):
    if sys.argv[i] == '-oh':
        oracleHome = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-jh':
        javaHome = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-dh':
        domainHome = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-name':
        domainName = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-port':
        domainPort = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-user':
        domainUser = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-password':
        domainPassword = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-rcuDb':
        dbUrl = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-rcuPrefix':
        dbPrefix = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-rcuSchemaPwd':
        dbPassword = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-adminPort':
        adminPort = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-adminName':
        adminName = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-prodMode':
        prodMode = sys.argv[i + 1]
        i += 2
    else:
        print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        usage()
        sys.exit(1)

domainCreator = CreateVeridataDomain(oracleHome,javaHome,domainHome)

domainCreator.createDomain(domainName,domainPort, domainUser, domainPassword, adminPort, adminName,dbPassword,dbPrefix,dbUrl,dbDriver,prodMode)
