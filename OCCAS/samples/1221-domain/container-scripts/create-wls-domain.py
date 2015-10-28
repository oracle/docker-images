# WebLogic on Docker Default Domain
#
# Default domain 'base_domain' to be created inside the Docker image for WLS
# 
# Since : October, 2014
# Author: bruno.borges@oracle.com
# ==============================================
admin_port = int(os.environ.get("ADMIN_PORT", "8001"))
admin_pass = os.environ.get("ADMIN_PASSWORD", "welcome1")

# Open default domain template
# ======================
readTemplate("/u01/oracle/weblogic/wlserver/common/templates/wls/wls.jar")

# Configure the Administration Server and SSL port.
# =========================================================
cd('Servers/AdminServer')
set('ListenAddress', '')
set('ListenPort', admin_port)

# Define the user password for weblogic
# =====================================
cd('/')
cd('Security/base_domain/User/weblogic')
cmo.setPassword(admin_pass)

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
# create('DS1', 'JDBCSystemResource')
# cd('JDBCSystemResource/myDataSource/JdbcResource/myDataSource')
# create('myJdbcDriverParams','JDBCDriverParams')
# cd('JDBCDriverParams/NO_NAME_0')
# set('DriverName','org.apache.derby.jdbc.ClientDriver')
# set('URL','jdbc:derby://localhost:1527/db;create=true')
# set('PasswordEncrypted', 'welcome1')
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

# cd('/JDBCSystemResource/DS1/JdbcResource/myDataSource')
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
cd('NMProperties')
set('ListenAddress','')
set('ListenPort',5556)
set('NativeVersionEnabled', 'false')
set('StartScriptEnabled', 'false')
set('SecureListener', 'false')

domain_path = '/u01/oracle/weblogic/user_projects/domains/base_domain'

writeDomain(domain_path)

# Exit WLST
# =========
exit()
