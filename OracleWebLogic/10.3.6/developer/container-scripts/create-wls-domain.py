
# Weblogic on Docker Default Domain
#
# Default domain 'base_domain' to be created inside the Docker image for WLS
#
# author: bruno.borges@oracle.com
# ==============================================
# Open default domain template
# ======================
readTemplate("/u01/oracle/weblogic/wlserver/common/templates/domains/wls.jar")
# Configure the Administration Server and SSL port.
# =========================================================
cd('Servers/AdminServer')
set('ListenAddress','')
set('ListenPort', 7001)
create('AdminServer','SSL')
cd('SSL/AdminServer')
set('Enabled', 'True')
set('ListenPort', 7002)
cd('/Servers/AdminServer/SSL/AdminServer')
cmo.setHostnameVerificationIgnored(true)
cmo.setHostnameVerifier(None)
cmo.setTwoWaySSLEnabled(false)
cmo.setClientCertificateEnforced(false)
# Define the user password for weblogic
# =====================================
cd('/')
cd('Security/base_domain/User/weblogic')
cmo.setPassword(os.environ["ADMIN_PASSWORD"])
# Please set password here before using this script, e.g. cmo.setPassword('value')
# Create a JMS Server
# ===================
cd('/')
create('myJMSServer', 'JMSServer')
# Create a JMS System resource
# ============================
cd('/')
create('myJmsSystemResource', 'JMSSystemResource')
cd('JMSSystemResource/myJmsSystemResource/JmsResource/NO_NAME_0')
# Create a JMS Queue and its subdeployment
# ========================================
myq=create('myQueue','Queue')
myq.setJNDIName('jms/myqueue')
myq.setSubDeploymentName('myQueueSubDeployment')
cd('/')
cd('JMSSystemResource/myJmsSystemResource')
create('myQueueSubDeployment', 'SubDeployment')
# Create and configure a JDBC Data Source, and sets the JDBC user
# ===============================================================
# IF YOU WANT TO HAVE A DEFAULT DATA SOURCE CREATED, UNCOMMENT THIS SECTION BEFORE BUILD
# cd('/')
# create('myDataSource', 'JDBCSystemResource')
# cd('JDBCSystemResource/myDataSource/JdbcResource/myDataSource')
# create('myJdbcDriverParams','JDBCDriverParams')
# cd('JDBCDriverParams/NO_NAME_0')
# set('DriverName','org.apache.derby.jdbc.ClientDriver')
# set('URL','jdbc:derby://localhost:1527/db;create=true')
# set('PasswordEncrypted', 'PBPUBLIC')
# set('UseXADataSourceInterface', 'false')
# create('myProps','Properties')
# cd('Properties/NO_NAME_0')
# create('user', 'Property')
# cd('Property/user')
# cmo.setValue('PBPUBLIC')
# cd('/JDBCSystemResource/myDataSource/JdbcResource/myDataSource')
# create('myJdbcDataSourceParams','JDBCDataSourceParams')
# cd('JDBCDataSourceParams/NO_NAME_0')
# set('JNDIName', java.lang.String("myDataSource_jndi"))
# cd('/JDBCSystemResource/myDataSource/JdbcResource/myDataSource')
# create('myJdbcConnectionPoolParams','JDBCConnectionPoolParams')
# cd('JDBCConnectionPoolParams/NO_NAME_0')
# set('TestTableName','SYSTABLES')
# Target resources to the servers
# ===============================
cd('/')
assign('JMSServer', 'myJMSServer', 'Target', 'AdminServer')
assign('JMSSystemResource.SubDeployment', 'myJmsSystemResource.myQueueSubDeployment', 'Target', 'myJMSServer')
# assign('JDBCSystemResource', 'myDataSource', 'Target', 'AdminServer')
# Write the domain and close the domain template
# ==============================================
setOption('OverwriteDomain', 'true')
setOption('ServerStartMode','prod')
cd('/')
#cd('NMProperties')
#set('ListenAddress','')
#set('NativeVersionEnabled', 'false')
writeDomain('/u01/oracle/weblogic/user_projects/domains/base_domain')
closeTemplate()
# Exit WLST
# =========
exit()
