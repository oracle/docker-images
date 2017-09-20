tsamDir = "/u01/oracle/oraHome/tsam12.2.2.0.0"
listenPort = int(os.environ.get("ADMIN_PORT", "7001"))
listenPortSSL = int(os.environ.get("ADMIN_SSL_PORT", "7002"))
admUser = os.environ.get("WLS_USER", "weblogic")
passwd = os.environ.get("WLS_PW")
cohClusterName = "tsam1222Cluster"
cohPort = 7576
domainName = os.environ.get("DOMAIN_NAME", "tsamdomain")
domainPath = tsamDir + '/wls/user_projects/domains/' + domainName
startMode = os.environ.get("START_MODE", "prod")

dsName = 'tsamds'
dsJNDIName = 'jdbc/tsamds'
dsDriver = 'oracle.jdbc.OracleDriver'
dsURL = 'jdbc:oracle:thin:@//' + os.environ.get("DB_CONNSTR")
dsUsername = os.environ.get("DB_TSAM_USER")
dsPassword = os.environ.get("DB_TSAM_PASSWD")

print ""
print "Start creating WebLogic domain with below parameters:"
print('Domain name: [%s]' % domainName);
print('Listen port: [%s]' % listenPort);
print('Listen port SSL: [%s]' % listenPortSSL);
print('Admin user: [%s]' % admUser);
# print('Start mode: [%s]' % startMode);
print('Domain path: [%s]' % domainPath);
print('Datasource name: [%s]' % dsName);
print('Datasource JNDI name: [%s]' % dsJNDIName);

setTopologyProfile('Compact')
selectTemplate('Oracle JRF', '12.2.1')
loadTemplates()

set('Name', domainName)
setOption('DomainName', domainName)

cd('/')
cd('CoherenceClusterSystemResource/defaultCoherenceCluster')
set('Name', cohClusterName)
cd('CoherenceResource/' + cohClusterName + '/CoherenceClusterParams/NO_NAME_0')
set('ClusterListenPort', cohPort)

cd('/')
cd('Servers/AdminServer')
set('ListenAddress','')
set('ListenPort', listenPort)
create('AdminServer','SSL')
cd('SSL/AdminServer')
set('Enabled', 'true')
set('ListenPort', listenPortSSL)

cd('/Security/%s/User/weblogic' % domainName)
cmo.setName(admUser)
cmo.setPassword(passwd)

setOption('OverwriteDomain', 'true')
# setOption('ServerStartMode', startMode)

# Create Datasource
# ==================
create(dsName, 'JDBCSystemResource')
cd('/JDBCSystemResource/' + dsName + '/JdbcResource/' + dsName)
cmo.setName(dsName)

cd('/JDBCSystemResource/' + dsName + '/JdbcResource/' + dsName)
create('myJdbcDataSourceParams','JDBCDataSourceParams')
cd('JDBCDataSourceParams/NO_NAME_0')
set('JNDIName', java.lang.String(dsJNDIName))
set('GlobalTransactionsProtocol', java.lang.String('None'))

cd('/JDBCSystemResource/' + dsName + '/JdbcResource/' + dsName)
create('myJdbcDriverParams','JDBCDriverParams')
cd('JDBCDriverParams/NO_NAME_0')
set('DriverName', dsDriver)
set('URL', dsURL)
set('passwordEncrypted', dsPassword)
set('UseXADataSourceInterface', 'false')

print 'create JDBCDriverParams Properties'
create('myProperties','Properties')
cd('Properties/NO_NAME_0')
create('user','Property')
cd('Property/user')
set('Value', dsUsername)

print 'create JDBCConnectionPoolParams'
cd('/JDBCSystemResource/' + dsName + '/JdbcResource/' + dsName)
create('myJdbcConnectionPoolParams','JDBCConnectionPoolParams')
cd('JDBCConnectionPoolParams/NO_NAME_0')
set('TestTableName','SQL SELECT 1 FROM DUAL')

# Assign
# ======
assign('JDBCSystemResource', dsName, 'Target', 'AdminServer')

writeDomain(domainPath)
closeTemplate()

exit()

print "Done!"
