#
#
# Copyright (c) 2016, 2021, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at
# https://oss.oracle.com/licenses/upl
#

import os
import sys

import com.oracle.cie.domain.script.jython.WLSTException as WLSTException

class SOA12214Provisioner:

    jrfDone = 0;

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
        },
        'soa_server2' : {
            'ListenAddress': '',
            'ListenPort': 8002,
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
        },
        'osb_server2' : {
            'ListenAddress': '',
            'ListenPort': 9002,
            'Machine': 'machine1',
            'Cluster': 'osb_cluster'
        }
    }


    JRF_12214_TEMPLATES = {
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

    SOA_12214_TEMPLATES = {
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/soa/common/templates/wls/oracle.soa.refconfig_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.ess.basic_template.jar',
            '@@ORACLE_HOME@@/em/common/templates/wls/oracle.em_ess_template.jar'
        ],
        'serverGroupsToTarget' : [ 'SOA-MGD-SVRS', 'ESS-MGD-SVRS' ]
    }

    SOA_B2B_12214_TEMPLATES = {
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/soa/common/templates/wls/oracle.soa.refconfig_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.ess.basic_template.jar',
            '@@ORACLE_HOME@@/em/common/templates/wls/oracle.em_ess_template.jar',
            '@@ORACLE_HOME@@/soa/common/templates/wls/oracle.soa.b2b.refconfig_template.jar'
        ],
        'serverGroupsToTarget' : [ 'SOA-MGD-SVRS', 'ESS-MGD-SVRS' ]
    }

    OSB_12214_TEMPLATES = {
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/osb/common/templates/wls/oracle.osb.refconfig_template.jar'
        ],
        'serverGroupsToTarget' : [ 'OSB-MGD-SVRS-ONLY' ]
    }

    JMSServersList  = ['SOAJMSServer','UMSJMSServer']

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

    def configureXADataSourcesForOSB(self):
        cd('/JDBCSystemResources/SOADataSource/JdbcResource/SOADataSource')
        cd('JDBCDriverParams/NO_NAME_0')
        set('DriverName', 'oracle.jdbc.xa.client.OracleXADataSource')
        cd('/JDBCSystemResources/OraSDPMDataSource/JdbcResource/OraSDPMDataSource')
        cd('JDBCDriverParams/NO_NAME_0')
        set('DriverName', 'oracle.jdbc.xa.client.OracleXADataSource')
        return

    def createDomain(self, name, user, password, db, dbPrefix, dbPassword, domainType):
        domainHome = self.createBaseDomain(name, user, password, domainType)

        if domainType == "soa" or domainType == "soaosb":
                self.extendSoaDomain(domainHome, db, dbPrefix, dbPassword)

        if domainType == "soab2b" or domainType == "soaosbb2b":
                self.extendSoaB2BDomain(domainHome, db, dbPrefix, dbPassword)

        if domainType == "osb" or domainType == "soaosb" or domainType == "soaosbb2b":
                self.extendOsbDomain(domainHome, db, dbPrefix, dbPassword, domainType)

        if persistentStore == 'jdbc':
            self.configureTlogJDBCStore(domainHome, domainType)
            self.reConfigureJMSStore(domainHome, domainType)
        else:
            print 'persistentStore = '+persistentStore+'...skipping JDBC reconfig'

    def configureTlogJDBCStore(self, domainHome, domainType):
        readDomain(domainHome)
        print 'START Configuring TLog JDBC Persistent Store'
        try:
            ## Get the schema information for 'WLSSchemaDataSource'
            schemaPrefix = self.getDSSchemaPrefix ('WLSSchemaDataSource')
            serverList = ['AdminServer']
            if domainType == "soa" or domainType == "soaosb" or domainType == "soab2b" or domainType == "soaosbb2b":
                serverList.extend(list(self.SOA_SERVERS.keys()))
            if domainType == "osb" or domainType == "soaosb" or domainType == "soaosbb2b":
                serverList.extend(list(self.OSB_SERVERS.keys()))
            print serverList
            for server in serverList:
                self.setTlogJDBCStoreAttributes(server, schemaPrefix) 
        except:
            raise
        updateDomain()
        closeDomain()

    def setTlogJDBCStoreAttributes(self, server, schemaPrefix):
        print 'UPDATE TLog JDBC Persistent Store properties for server '+server
        try:
            cd ('/')
            cd ('/Servers/'+server)
            try :
                tlog = get('TransactionLogJDBCStore')
                print 'tlog = '+ str(tlog)
                if (tlog != None and tlog.getDataSource() != None and tlog.isEnabled()) :
                    print ' tlo ',tlog , ' DS ' , tlog.getDataSource(), ' enabled ' , tlog.isEnabled()            
                    return false
            except Exception, detail:
              print 'Ignoring, Failed to xheck if TLog JDBC Store exists ['+server+']', detail

            ## Create TransactionLog JDBC Store
            print 'Creating TLOG JDBC store ...'
            create(server,'TransactionLogJDBCStore')

            cd ('TransactionLogJDBCStore/'+server)      
            set('DataSource','WLSSchemaDataSource')

            print 'Using TLogs WLStore prefixName '+schemaPrefix+'.TLOG_'+server.upper()+'_'
            set('PrefixName',schemaPrefix+'.TLOG_'+server.upper()+'_')
            set('Enabled','true')
            return true

        except Exception, detail:
            print 'Failed to configure TLog JDBC Persistent Store for ['+server+']', detail
            raise Exception ('Exception setting SOA Tlog JDBC Store Attributes')

    def reConfigureJMSStore(self, domainHome, domainType):
        readDomain(domainHome)
        print time.asctime(time.localtime(time.time())) + ' : Read Domain: %s' % domainHome
        configUpdated = false
        serverList = []
        if domainType == "soa" or domainType == "soaosb" or domainType == "soab2b" or domainType == "soaosbb2b":
            serverList.extend(list(self.SOA_SERVERS.keys()))
        if domainType == "osb" or domainType == "soaosb" or domainType == "soaosbb2b":
            serverList.extend(list(self.OSB_SERVERS.keys()))
        print serverList
        dataSource = self.getDSMBean('WLSSchemaDataSource')
        if dataSource == None:
            print time.asctime(time.localtime(time.time())) + ' : WLSSchemaDataSource not exists in this domain, skipping'
            closeDomain()
            return
        schemaPrefix = self.getDSSchemaPrefix ('WLSSchemaDataSource')
        cmd = cd('/')
        jmsServers = cmo.getJMSServers()
        print jmsServers
        for jmsServer in jmsServers:
            jmsServerName = jmsServer.getName()
            jmsFlag = self.isConfigurableJMSServer(jmsServerName)
            if (jmsFlag == true):
                cd('/JMSServer/'+jmsServerName)
                jmsServerTargetName = ls('/JMSServer/'+jmsServerName,returnMap='true',returnType='a')['Target']
                print time.asctime(time.localtime(time.time())) + ' : [JMSServer]: ' + str(jmsServerName)+ ' : [TargetServer]: ' + str(jmsServerTargetName)
                if jmsServerTargetName == None or len(jmsServerTargetName) < 1:
                    print time.asctime(time.localtime(time.time())) + ' WARNING !!! : Not expected but CONTINUE processing ... skipping ['+str(jmsServerName)+\
                                '] as it is not targetted '+str(jmsServerTargetName)
                    continue
                flag = self.checkServerInCluster(jmsServerTargetName, serverList)
                if (flag == true):
                    configUpdated = configUpdated | self.configureJMSJDBCStore (jmsServerTargetName, jmsServerName, schemaPrefix, dataSource)
                else:
                    print time.asctime(time.localtime(time.time())) + ' WARNING !!! : Not expected but CONTINUE processing, Target '+\
                               str(jmsServerTargetName)+' is not part of configured Servers ['+\
                               str(serverList)+'] can not be configured to use JDBC Persistent Store'
                    continue
            else:
                print time.asctime(time.localtime(time.time())) + ' : CONTINUE processing ... ['+jmsServerName+\
                              '] will not be configured to use JDBC Persistent Store'
                continue
        print time.asctime(time.localtime(time.time())) + ' : clean UnUsedSOAStores from Domain : '+ domainHome
        configUpdated= configUpdated | self.cleanunUsedSOAStores()
        if configUpdated:
            print time.asctime(time.localtime(time.time())) + ' : Updating Domain : ',domainHome
            updateDomain()
        else:
            print time.asctime(time.localtime(time.time())) + ' : No Updates Closing Domain with out update ',domainHome
        closeDomain()
        print time.asctime(time.localtime(time.time())) + ' : COMPLETED jms jdbc store config '

    def configureJMSJDBCStore(self, jmsServerTargetName, jmsServerName, schemaPrefix, dataSource):
        configUpdated = false
        jmsJdbcStoreName = self.getJMSJDBCStore(jmsServerName,jmsServerTargetName, schemaPrefix, dataSource)
        if(jmsJdbcStoreName == None):
            print time.asctime(time.localtime(time.time())) + ' : Skipping '+str(jmsServerName)+' already configured .'
            return false
        else:
            cmo = cd('/JMSServer/'+jmsServerName)
            oldPersistence = cmo.getPersistentStore().getName()
            jdbcStoreBean = self.getJDBCStore(jmsJdbcStoreName)
            print time.asctime(time.localtime(time.time())) + ' : oldPersistence '+str(oldPersistence)+' jmsJdbcStoreName '+jmsJdbcStoreName+' jdbcStoreBean name  '+str(jdbcStoreBean.getName())
            configUpdated = true
            if(jmsJdbcStoreName != oldPersistence):
                try:
                    cmo.setPersistentStore(jdbcStoreBean)
                    configUpdated = true
                except Exception, detail:
                    dumpStack()
                    print time.asctime(time.localtime(time.time()))+' : setPersistentStore failed for jmsServerName '+str(jmsServerName), detail , " !!!!!! If the exception above says 'com.oracle.cie.domain.ValidateException: The property value is duplicated'; means you did not apply CIE fix of bug 22175233 "     
                    raise
                if(self.isDeletableJDBCStore(oldPersistence) == Boolean(true)):
                    delete(oldPersistence,'JDBCStore')
                    print time.asctime(time.localtime(time.time())) + ' : Deleted JDBCStore '+oldPersistence
                elif(self.isDeletableFileStore(oldPersistence) == Boolean(true)) :
                    delete(oldPersistence,'FileStore')
                    print time.asctime(time.localtime(time.time())) + ' : Deleted FileStore '+oldPersistence   
                else:
                    print time.asctime(time.localtime(time.time())) + ' : '+ oldPersistence+' not deleted; it may be still in use' 
            else:
                print time.asctime(time.localtime(time.time())) + ' : Skipping '+str(jmsServerName)+' aready configured .'
        print time.asctime(time.localtime(time.time())) + ' : END Configuring JDBC Persistent Store for ['+jmsServerName+'] configUpdated '+str(Boolean(configUpdated))
        return configUpdated

    def getJMSJDBCStore(self, jmsServerName,jmsServerTargetName, schemaPrefix, dataSource):
        try: 
            cd('/JMSServers/'+jmsServerName)
            originalStore = None
            if (get('PersistentStore') != None):
                originalStore = get('PersistentStore').getName()
            else:
                print time.asctime(time.localtime(time.time())) + ' : WARNING!!! No PersistentStore for : ' +str(jmsServerName) +" jmsServerTargetName "+str(jmsServerTargetName)+ ' Skipping '
                return None
            print time.asctime(time.localtime(time.time())) + ' : Parsing PersistentStore: ' +str(originalStore) +" jmsServerTargetName "+str(jmsServerTargetName)
            words = {'File':'JDBC', 'file':'JDBC', 'FILE':'JDBC'}
            jStore = self.replace_all (originalStore, words)
            if 'JDBC' in jStore:
                print time.asctime(time.localtime(time.time())) + ' : File Store name substituted with JDBC ... '+str(jStore)
            else:
                jStore = jmsServerName.replace ('Server','JDBC')
                print time.asctime(time.localtime(time.time())) + ' : Server name substituted with JDBC ... '+str(jStore)
            cd('/')
            store = self.getJDBCStore(jStore)
            if (store == None):
                self.createJMSJDBCStore(jStore, jmsServerName, jmsServerTargetName, schemaPrefix, dataSource)
            else:
                print ' jdbcStore ' , store.getTargets() , ' Expected ', jmsServerTargetName
                self.targetJMSJDBCStore(jStore, jmsServerName, jmsServerTargetName, schemaPrefix, dataSource)
            cd('/')
            cd('/JDBCStore/'+jStore)
            storetarget = ls('/JDBCStore/'+jStore,returnMap='true',returnType='a')['Target']
            matchingTargets = Boolean(storetarget == jmsServerTargetName)
            # This should not happen, fail if it does
            if( not matchingTargets) :
                raise Exception ('Target for JMS Server and store doesnt match storetarget : '+\
                                  str(storetarget) +' jmsServerTargetName '+str(jmsServerTargetName))
        except Exception, detail:
            print time.asctime(time.localtime(time.time())) + ' : ERROR while processing SOA JMS JDBC Persistent Store for '+str(jmsServerName) , detail
            raise

        return jStore

    def getJDBCStore(self, jStore):
        try: 
            cd('/')       
            print time.asctime(time.localtime(time.time())) + ' : '+ 'Checking JDBC stores'
            jdbcStores = cmo.getJDBCStores()
            for jdbcStore in jdbcStores:
                if jdbcStore.getName()  == jStore:
                    return jdbcStore
        except:
            raise Exception ('Exception on getting JDBC store for '+str(jStore))
        print time.asctime(time.localtime(time.time())) + ' : Did not find store for '+str(jStore)

    def createJMSJDBCStore(self, jStore, jmsServerName, jmsServerTargetName, schemaPrefix, dataSource):
        ## Create the JDBC Store
        print time.asctime(time.localtime(time.time())) + ' : Creating JDBC Store: ' + jStore +' for '+jmsServerName
        jmsTarget = self.getTargetMbean(jmsServerTargetName)
        cd('/')
        create(jStore,'JDBCStore')
        prefixName = jStore.replace ('JDBCStore','')
        prefixName = prefixName.replace ('Server','')
        prefixName = prefixName.replace('_auto_', '')
        cd('/JDBCStore/'+jStore)
        cmo.setDataSource(dataSource)
        print time.asctime(time.localtime(time.time())) + ' : Created Store '+jStore+' Using JMS WLStore prefixName :'+schemaPrefix+'.'+prefixName+'_'
        cmo.setPrefixName(schemaPrefix+'.'+prefixName+'_')
        jmsTargets = jarray.array([jmsTarget], Class.forName("weblogic.management.configuration.TargetMBean"))
        cmo.setTargets(jmsTargets)

    def targetJMSJDBCStore(self, jStore, jmsServerName, jmsServerTargetName, schemaPrefix, dataSource):
        print time.asctime(time.localtime(time.time())) + ' : Creating JDBC Store: ' + jStore +' for '+jmsServerName
        jmsTarget = self.getTargetMbean(jmsServerTargetName)
        cd('/')
        cd('/JDBCStore/'+jStore)
              
        jmsTargets = jarray.array([jmsTarget], Class.forName("weblogic.management.configuration.TargetMBean"))
        print ' current Target ',cmo.getTargets(),' Expected Target ', jmsTarget
        cmo.setTargets(jmsTargets)
        print time.asctime(time.localtime(time.time())) + ' : JDBC Store '+jStore+' Targetted to  :',jmsTarget

    def isDeletableJDBCStore (self, storeName):
        for item in cmo.getJDBCStores():
            if storeName == item.getName():
                for jms in cmo.getJMSServers():
                    if (jms.getPersistentStore() != None and str(jms.getPersistentStore().getName()) == str(storeName) ):
                        return Boolean('false');
                return Boolean('true');
        return Boolean('false');

    def isDeletableFileStore (self, storeName):
        for item in cmo.getFileStores():
            if storeName == item.getName():
                for jms in cmo.getJMSServers():
                    if (jms.getPersistentStore() != None and str(jms.getPersistentStore().getName()) == str(storeName) ):
                        return Boolean('false');
                return Boolean('true');
        return Boolean('false');

    def cleanunUsedSOAStores (self):
        cd('/')
        ## list of eligible SOA JMS Store to cleanup, if they are not in use
        soacleanJDBCStoresList  = [] #['AGJMSJDBCStore','PS6SOAJMSJDBCStore','BPMJMSJDBCStore']
        soacleanFileStoresList  = ['SOAJMSFileStore']      
        configUpdated = false
        for fileStore in cmo.getFileStores():
            for soaStore in soacleanFileStoresList:
                if fileStore.getName().find(soaStore) != -1:
                    if (self.isDeletableFileStore(fileStore.getName()) == Boolean(true)) :
                        delete(fileStore.getName(),'FileStore')
                        print time.asctime(time.localtime(time.time())) + ' : Deleted FileStore '+fileStore.getName() 
                        configUpdated = true

        for jdbcStore in cmo.getJDBCStores():
            for soaStore in soacleanJDBCStoresList:
                if jdbcStore.getName().find(soaStore) != -1:
                    if (self.isDeletableJDBCStore(jdbcStore.getName()) == Boolean(true)) :
                        delete(jdbcStore.getName(),'JDBCStore')
                        print time.asctime(time.localtime(time.time())) + ' : Deleted JDBCStore '+jdbcStore.getName() 
                        configUpdated = true
    
        print time.asctime(time.localtime(time.time())) + ' : END cleanunUsedSOAStores configUpdated '+str(Boolean(configUpdated))
        return configUpdated

    def getTargetMbean (self, targetName):
        cd('/')
        migratableTargets = cmo.getMigratableTargets();
        for item in migratableTargets:
            if item.getName() == targetName:
                print time.asctime(time.localtime(time.time())) + ' : migratableTarget match for '+targetName+' ' +str(item)
                return item
        for item in cmo.getServers():
            if item.getName() == targetName :
                print time.asctime(time.localtime(time.time())) + ' : Server match for '+targetName+' ' +str(item)
                return item
        print time.asctime(time.localtime(time.time())) + ' : No Matching target for '+targetName

    def replace_all(self, text, words):
        for i,j in words.iteritems():
            text = text.replace(i, j)
        return text

    def checkServerInCluster(self, serverName, serverList):
        if serverName == None or len(serverName) < 1:
            print (Time.asctime(Time.localtime(Time.time())) +' : Server Target not valid. ', str(serverName))
            return false

        for item in serverList:
            if serverName.find(item) != -1:
                return true
        return false

    def isConfigurableJMSServer(self, jmsServerName):
        canBeConfigured = false
        ## CHECK whether JMS Server can be configured to use JDBC Persistent Store
        for item in self.JMSServersList:
            if jmsServerName.find(item) != -1:
                ## MATCH -  'jmsServerName' can be configured to use JDBC Persistent Store
                canBeConfigured = true
                break
        return canBeConfigured

    def getDSSchemaPrefix (self, jdbcDS):
        try:
            cd ('/')
            dSName = jdbcDS
            while (dSName != "") :
                print time.asctime(time.localtime(time.time())) + ' : dSName =>'+dSName
                cd ('/JDBCSystemResources/'+dSName+'/JdbcResource/'+dSName+'/JDBCDataSourceParams/NO_NAME_0')
                dSList = get('DataSourceList')
                if(dSList == None) :
                    cd ('/JDBCSystemResources/'+dSName+'/JdbcResource/'+dSName+'/JDBCDriverParams/NO_NAME_0/Properties/NO_NAME_0/Property/user')
                    schemaPrefix = cmo.getValue ()
                    print time.asctime(time.localtime(time.time())) + ' : schemaPrefix '+schemaPrefix
                    dSName = ""
                    break;
                else :
                    print time.asctime(time.localtime(time.time())) + ' : multi-data source detected ...'
                    print time.asctime(time.localtime(time.time())) + ' : dSList =>'+dSList
                    dSName = dSList.split(',')[0]
        except:
            raise Exception ('Exception on getting data source Schema info for '+jdbcDS)
        return schemaPrefix

    def getDSMBean(self, jdbcDS):
        try:
            cd ('/JDBCSystemResources/'+jdbcDS)
            return cmo
        except:
            raise Exception ('Exception on getting data source')
        return

    def createBaseDomain(self, name, user, password, domainType):
        baseTemplate = self.replaceTokens(self.JRF_12214_TEMPLATES['baseTemplate'])

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

        if domainType == "soa" or domainType == "soaosb" or domainType == "soab2b" or domainType == "soaosbb2b":

                print 'INFO: Creating SOA cluster...'
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

        if domainType == 'osb' or domainType == "soaosb" or domainType == "soaosbb2b":

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

        if self.jrfDone == 1:
            print 'INFO: JRF templates already applied '
            return

        print 'INFO: Applying JRF templates...'
        for extensionTemplate in self.JRF_12214_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))

        self.jrfDone = 1
        return

    def applySOATemplates(self):
        print 'INFO: Applying SOA templates...'
        for extensionTemplate in self.SOA_12214_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))
        return
    
    def applySOAB2BTemplates(self):
        print 'INFO: Applying SOA B2B templates...'
        for extensionTemplate in self.SOA_B2B_12214_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))
        return

    def applyOSBTemplates(self):
        print 'INFO: Applying OSB templates...'
        for extensionTemplate in self.OSB_12214_TEMPLATES['extensionTemplates']:
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

        print 'INFO: deleting ess_server1'
        cd('/')
        delete('ess_server1', 'Server')
        print 'INFO: ess_server1 deleted'

        if 'soa_server1' not in self.SOA_SERVERS:
	        print 'INFO: deleting soa_server1'
	        cd('/')
	        delete('soa_server1','Server')
	        print 'INFO: deleted soa_server1'

        self.configureJDBCTemplates(db,dbPrefix,dbPassword)
        self.configureXADataSources()

        print 'INFO: Targeting Server Groups...'
        serverGroupsToTarget = list(self.JRF_12214_TEMPLATES['serverGroupsToTarget'])
        serverGroupsToTarget.extend(self.SOA_12214_TEMPLATES['serverGroupsToTarget'])

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

    def extendSoaB2BDomain(self, domainHome, db, dbPrefix, dbPassword):
        self.readAndApplyJRFTemplates(domainHome)
        self.applySOAB2BTemplates()

        print 'INFO: Extension Templates added'

        print 'INFO: deleting ess_server1'
        cd('/')
        delete('ess_server1', 'Server')
        print 'INFO: ess_server1 deleted'

        if 'soa_server1' not in self.SOA_SERVERS:
	        print 'INFO: deleting soa_server1'
	        cd('/')
	        delete('soa_server1','Server')
	        print 'INFO: deleted soa_server1'

        self.configureJDBCTemplates(db,dbPrefix,dbPassword)
        self.configureXADataSources()

        print 'INFO: Targeting Server Groups...'
        serverGroupsToTarget = list(self.JRF_12214_TEMPLATES['serverGroupsToTarget'])
        serverGroupsToTarget.extend(self.SOA_B2B_12214_TEMPLATES['serverGroupsToTarget'])

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
    
    def extendOsbDomain(self, domainHome, db, dbPrefix, dbPassword, domainType):
        self.readAndApplyJRFTemplates(domainHome)
        self.applyOSBTemplates()

        print 'INFO: Extension Templates added'

        if 'osb_server1' not in self.OSB_SERVERS:
                print 'INFO: deleting osb_server1'
                cd('/')
                delete('osb_server1','Server')
                print 'INFO: deleted osb_server1'

        self.configureJDBCTemplates(db,dbPrefix,dbPassword)
        self.configureXADataSourcesForOSB()

        print 'INFO: Targeting Server Groups...'
        serverGroupsToTarget = list(self.JRF_12214_TEMPLATES['serverGroupsToTarget'])
        serverGroupsToTarget.extend(self.OSB_12214_TEMPLATES['serverGroupsToTarget'])

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
          '-domainType <soa|osb|soaosb|soab2b|soaosbb2b> -persistentStore <jdbc|file>'
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
persistentStore = 'jdbc'

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
    elif sys.argv[i] == '-persistentStore':
        persistentStore = sys.argv[i + 1]
        i += 2
    else:
        print 'INFO: Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        usage()
        sys.exit(1)


provisioner = SOA12214Provisioner(oracleHome, javaHome, domainParentDir)
provisioner.createDomain(domainName, domainUser, domainPassword, rcuDb, rcuSchemaPrefix, rcuSchemaPassword, domainType)
