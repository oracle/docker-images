from java.io import FileInputStream
import java.lang
import os
import string

propInputStream = FileInputStream("/u01/oracle/jms-config.properties")
configProps = Properties()
configProps.load(propInputStream)

#Read Properties
##############################

# 1 - Connecting details - read from system arguments
##############################
domainname = os.environ.get('DOMAIN_NAME', 'base_domain')
admin_name = os.environ.get('ADMIN_NAME', 'AdminServer')
domainhome = os.environ.get('DOMAIN_HOME', '/u01/oracle/user_projects/domains/' + domainname)
adminport = os.environ.get('ADMIN_PORT', '7001')
username = os.environ.get('ADMIN_USER', 'weblogic')
password = os.environ.get('ADMIN_PASSWORD', 'welcome1')

print('admin_name  : [%s]' % admin_name);
print('admin_user  : [%s]' % username);
print('admin_password  : [%s]' % password);
print('admin_port  : [%s]' % adminport);
print('domain_home  : [%s]' % domainhome);

clusterName = os.environ.get("CLUSTER_NAME", "DockerCluster")

 
migratableTargetName = configProps.get("migratabletarget.name")
#machineName = configProps.get("machine.name")

# 2 - JMSServer details
jmsServerName = configProps.get("jms.server.name")
storeName = configProps.get("store.name")
storePath = configProps.get("store.path")
 
# 3 - SystemModule Details
systemModuleName = configProps.get("system.module.name")
 
# 4 - ConnectionFactory Details
connectionFactoryName = configProps.get("connection.factory.name")
ConnectionFactoryJNDIName = configProps.get("connection.factory.jndi.name")
 
# 5 - SubDeployment, Queue & Topic Details
SubDeploymentName = configProps.get("sub.deployment.name")
queueName = configProps.get("queue.name")
queueJNDIName = configProps.get("queue.jndi.name")
topicName = configProps.get("topic.name")
topicJNDIName = configProps.get("topic.jndi.name")

# Connect to the AdminServer
# ==========================
#Connection to the Server
print 'connection to Weblogic Admin Server'
connect(username,password,"t3://localhost:7001")

#Print Server Information
domainConfig()
serverNames = cmo.getServers()
machineNames = cmo.getMachines()
domainRuntime()

runningServer = ''
for server in serverNames:
	name = server.getName()
	print 'server : '+name
	
	try:
		cd('/ServerRuntimes/'+name)
	except Exception, e:
		print 'Server :'+name +' seems to be down '
		print 'Starting Server '+name
		start(name,'Server')
		Thread.sleep(5000)
		continue

	serverState = cmo.getState()
	if serverState == "RUNNING":
		print 'Server ' + name + ' is :\033[1;32m' + serverState + '\033[0m'		
	elif serverState == "STARTING":
		print 'Server ' + name + ' is :\033[1;33m' + serverState + '\033[0m'
	elif serverState == "UNKNOWN":
		print 'Server ' + name + ' is :\033[1;34m' + serverState + '\033[0m'
	else:

		print 'Server ' + name + ' is :\033[1;31m' + serverState + '\033[0m'

for server in serverNames:
	name = server.getName()
	try:
		if 'admin' in name.lower():
			continue
		#if name == 'AdminServer' or name == 'Admin' or name:
		#	continue
		
		cd('/ServerRuntimes/'+name)
		runningServer = name
		break
	except Exception, e:
		print 'Server :'+name+'seems to be down'

print 'Running Server '+runningServer


domainConfig()
clusterAddress=''
numberofservers=0
i=1;
for server in serverNames:
		name = server.getName()
		try:
                        numberofservers=i
			if 'admin' in name.lower():
				continue
			print 'server '+name
			cd('/')
			print 'going to dockerNAP'
			cd('/Servers/'+name+'/NetworkAccessPoints/dockerNAP')
			print 'in dockerNAP'
			portNumber = cmo.getPublicPort()
#			portNumber = server.getListenPort()
			print 'portNumber '+ `portNumber`
			host = cmo.getPublicAddress()
			print 'host ' + `host`
			if i > 1:
				clusterAddress = clusterAddress + ','
			
			clusterAddress = clusterAddress + host + ':' + `portNumber`                 
			i= i + 1
		except Exception, e:
			print 'Error creating up cluster Address'

print 'Cluster Address '+clusterAddress

machineName=''
i=1;
for machine in machineNames:
		name = machine.getName()
		try:
			print 'machine '+name
			if i > 1:
				machineName = machineName + ','
			
			machineName = machineName + `name`                 
			i= i + 1
		except Exception, e:
			print 'Error creating up machine names'

print 'Candidate machines '+machineName

#Cleanup
###########################
cd('/')
edit()

print 'Removing JMS System Module, JMS Server & FileStore....'
startEdit()
cd('/')
cmo.destroyJMSSystemResource(getMBean('/JMSSystemResources/'+systemModuleName))
cmo.destroyJMSServer(getMBean('/JMSServers/'+jmsServerName))
cmo.destroyFileStore(getMBean('/FileStores/'+storeName))
activate()



#Create Migratable Target
##############################

#print 'Setting Migration Basis as Consensus...'
#cd('/')
#startEdit()

#The following required server restart. So, moved into ../config_NAP.py
#cd('/Clusters/'+clusterName)
#cmo.setMigrationBasis('consensus')
#cmo.setClusterAddress(clusterAddress)
machineArray = [] 
for machine in machineNames:
	name = machine.getName()
	machineArray.append(ObjectName('com.bea:Name='+name+',Type=Machine'))

for p in machineArray: print p
#print 'Candidate Machine array ' + machineArray
#set('CandidateMachinesForMigratableServers',jarray.array(machineArray, ObjectName))
#activate()

#List of all servers will be stored in the list
#print 'Creating Migratable Target...'

#candidateServerList = []

#for server_loop1 in serverNames:
#	name = server_loop1.getName()
#	if 'admin' in name.lower():
#			continue
#	candidateServerList.append(ObjectName('com.bea:Name='+name+',Type=Server'))
#
#for p in candidateServerList: print p

#cd('/')
#startEdit()

#ref = getMBean('/MigratableTargets/' + migratableTargetName)
#if(ref != None):
#	print '########## Migratable Target already exists with name '+ migratableTargetName
#else:
#	cmo.createMigratableTarget(migratableTargetName)

#cd('/MigratableTargets/'+migratableTargetName)
#cmo.setCluster(getMBean('/Clusters/'+clusterName))
#cmo.setUserPreferredServer(getMBean('/Servers/'+runningServer))
#cmo.setMigrationPolicy('exactly-once')
#set('ConstrainedCandidateServers',jarray.array(candidateServerList, ObjectName))
#cmo.setNumberOfRestartAttempts(6)
#cmo.setNonLocalPostAllowed(false)
#cmo.setRestartOnFailure(false)
#cmo.setPostScriptFailureFatal(true)
#cmo.setSecondsBetweenRestarts(30)
#activate()


#creating FileStore
############################

print 'Creating JMS FileStore....'

cd('/')
startEdit()
ref = getMBean('/FileStores/' + storeName)

if(ref != None):
	print '########## File Store already exists with name '+ storeName
else:
	cmo.createFileStore(storeName)
	print '===> Created FileStore - ' + storeName
	Thread.sleep(10)
	cd('/FileStores/'+storeName)
	cmo.setDirectory(storePath)
	print 'Running Server '+runningServer
	#set('Targets',jarray.array([ObjectName('com.bea:Name='+runningServer+' (migratable),Type=MigratableTarget')], ObjectName))
#	set('Targets',jarray.array([ObjectName('com.bea:Name='+migratableTargetName+',Type=MigratableTarget')], ObjectName))

#activate()


#Creating JMS Server
############################

print 'Creating JMS Server....'
startEdit()
cd('/')
ref = getMBean('/JMSServers/' + jmsServerName)

if(ref != None):
	print '########## JMS Server already exists with name '+ jmsServerName
else:
	cmo.createJMSServer(jmsServerName)
	print '===> Created JMS Server - ' + jmsServerName
	Thread.sleep(10)
	cd('/JMSServers/'+jmsServerName)
	cmo.setPersistentStore(getMBean('/FileStores/'+storeName))
	#set('Targets',jarray.array([ObjectName('com.bea:Name='+runningServer+' (migratable),Type=MigratableTarget')], ObjectName))
#	set('Targets',jarray.array([ObjectName('com.bea:Name='+migratableTargetName+',Type=MigratableTarget')], ObjectName))

activate()

#Creating JMS Module
#########################

print 'Creating JMS Module....in cluster: '+clusterName

startEdit()
cd('/')

ref = getMBean('/JMSSystemResources/' + systemModuleName)

if(ref != None):
	print '########## JMS System Module Already exists with name '+ systemModuleName
else:
	cmo.createJMSSystemResource(systemModuleName)
	print '===> Created JMS System Module - ' + systemModuleName
	cd('/JMSSystemResources/'+systemModuleName)
	set('Targets',jarray.array([ObjectName('com.bea:Name='+clusterName+',Type=Cluster')], ObjectName))

activate()


#Creating JMS SubDeployment
############################

print 'Creating JMS SubDeployment....'

startEdit()

ref = getMBean('/JMSSystemResources/'+systemModuleName+'/SubDeployments/'+SubDeploymentName)
if(ref != None):
	print '########## JMS SubDeployment Already exists with name '+ SubDeploymentName + 'in module '+systemModuleName
else:
	cmo.createSubDeployment(SubDeploymentName)
	print '===> Created JMS SubDeployment - ' + systemModuleName
	cd('/JMSSystemResources/'+systemModuleName+'/SubDeployments/'+SubDeploymentName)
	set('Targets',jarray.array([ObjectName('com.bea:Name='+jmsServerName+',Type=JMSServer')], ObjectName))

activate()

#Creating JMS Connection Factory
###############################

print 'Creating JMS Connection Factory....'
startEdit()

ref = getMBean('/JMSSystemResources/'+systemModuleName+'/JMSResource/'+systemModuleName+'/ConnectionFactories/'+connectionFactoryName)

if(ref != None):
	print '########## JMS Connection Factory Already exists with name '+ connectionFactoryName + 'in module '+systemModuleName
else:
	cd('/JMSSystemResources/'+systemModuleName+'/JMSResource/'+systemModuleName)
	cmo.createConnectionFactory(connectionFactoryName)
	print '===> Created Connection Factory - ' + connectionFactoryName
	
	cd('/JMSSystemResources/'+systemModuleName+'/JMSResource/'+systemModuleName+'/ConnectionFactories/'+connectionFactoryName)
	cmo.setJNDIName(ConnectionFactoryJNDIName)

	cd('/JMSSystemResources/'+systemModuleName+'/JMSResource/'+systemModuleName+'/ConnectionFactories/'+connectionFactoryName+'/SecurityParams/'+connectionFactoryName)
	cmo.setAttachJMSXUserId(false)

	cd('/JMSSystemResources/'+systemModuleName+'/JMSResource/'+systemModuleName+'/ConnectionFactories/'+connectionFactoryName+'/ClientParams/'+connectionFactoryName)
	cmo.setClientIdPolicy('Restricted')
	cmo.setSubscriptionSharingPolicy('Exclusive')
	cmo.setMessagesMaximum(10)

	cd('/JMSSystemResources/'+systemModuleName+'/JMSResource/'+systemModuleName+'/ConnectionFactories/'+connectionFactoryName+'/TransactionParams/'+connectionFactoryName)
	cmo.setXAConnectionFactoryEnabled(true)

	cd('/JMSSystemResources/'+systemModuleName+'/SubDeployments/'+SubDeploymentName)
	set('Targets',jarray.array([ObjectName('com.bea:Name='+jmsServerName+',Type=JMSServer')], ObjectName))

	cd('/JMSSystemResources/'+systemModuleName+'/JMSResource/'+systemModuleName+'/ConnectionFactories/'+connectionFactoryName)
	cmo.setSubDeploymentName(''+SubDeploymentName)

activate()


#Creating JMS Distributed Queue
##################################

print 'Creating JMS Distributed Queue....'

startEdit()

ref = getMBean('/JMSSystemResources/'+systemModuleName+'/JMSResource/'+systemModuleName+'/UniformDistributedQueues/'+queueName)

if(ref != None):
	print '########## JMS Queue Already exists with name '+ queueName + 'in module '+systemModuleName
else:
	cd('/JMSSystemResources/'+systemModuleName+'/JMSResource/'+systemModuleName)
	cmo.createUniformDistributedQueue(queueName)
	print '===> Created Distributed Queue - ' + queueName

	cd('/JMSSystemResources/'+systemModuleName+'/JMSResource/'+systemModuleName+'/UniformDistributedQueues/'+queueName)
	cmo.setJNDIName(queueJNDIName)
	
	cd('/JMSSystemResources/'+systemModuleName+'/SubDeployments/'+SubDeploymentName)
	set('Targets',jarray.array([ObjectName('com.bea:Name='+jmsServerName+',Type=JMSServer')], ObjectName))

	cd('/JMSSystemResources/'+systemModuleName+'/JMSResource/'+systemModuleName+'/UniformDistributedQueues/'+queueName)
	cmo.setSubDeploymentName(''+SubDeploymentName)

activate()


#Creating JMS Distributed Topic
#################################

print 'Creating JMS Distributed Topic....'

startEdit()

ref = getMBean('/JMSSystemResources/'+systemModuleName+'/JMSResource/'+systemModuleName+'/UniformDistributedTopics/'+topicName)

if(ref != None):
	print '########## JMS Topic Already exists with name '+ topicName + 'in module '+systemModuleName
else:
	cd('/JMSSystemResources/'+systemModuleName+'/JMSResource/'+systemModuleName)
	cmo.createUniformDistributedTopic(topicName)
	print '===> Created Distributed Topic - ' + topicName

	cd('/JMSSystemResources/'+systemModuleName+'/JMSResource/'+systemModuleName+'/UniformDistributedTopics/'+topicName)
	cmo.setJNDIName(topicJNDIName)
	cmo.setForwardingPolicy('Replicated')
	
	cd('/JMSSystemResources/'+systemModuleName+'/SubDeployments/'+SubDeploymentName)
	set('Targets',jarray.array([ObjectName('com.bea:Name='+jmsServerName+',Type=JMSServer')], ObjectName))

	cd('/JMSSystemResources/'+systemModuleName+'/JMSResource/'+systemModuleName+'/UniformDistributedTopics/'+topicName)
	cmo.setSubDeploymentName(''+SubDeploymentName)

activate()
disconnect()
exit()
print '###### Completed configuration of all required JMS Objects ##############'
