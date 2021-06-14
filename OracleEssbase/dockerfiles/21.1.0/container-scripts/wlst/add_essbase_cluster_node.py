#
# Copyright (c) 2021, Oracle and/or its affiliates.
#
# This script adds an Essbase server and machine to the cluster

import os
import socket
import sys

def noneIfNoValue(v):
   if v is None or v == 'NO_VALUE':
      return None
   return v

try:
   if len(sys.argv) < 9:
      print 'Expected number of arguments not passed!!'
      sys.exit(1)

   domainHome=sys.argv[1]
   domainName=os.path.basename(domainHome)
   nodeIndex=int(sys.argv[2])
   machineNamePrefix=sys.argv[3]
   nodeManagerListenAddress=noneIfNoValue(sys.argv[4])
   nodeManagerPort=int(sys.argv[5])
   managedServerListenAddress=noneIfNoValue(sys.argv[6])
   managedServerPort=noneIfNoValue(sys.argv[7])
   managedServerSslPort=noneIfNoValue(sys.argv[8])

   readDomain(domainHome)

   ### Standard machine config (the name just needs to match later use-cases, including when creating system components
   machineName = machineNamePrefix + str(nodeIndex)
   managedServerName = 'essbase_server' + str(nodeIndex)

   print 'Adding machine ' + machineName

   cd('/')
   create(machineName, 'Machine')
   cd('/Machines/' + machineName)
   create(machineName, 'NodeManager')
   cd('NodeManager/' + machineName)

   # the nodemanager listen address needs to be set correct for scale-out use-cases
   set('NMType', 'SSL')
   cmo.setListenAddress(nodeManagerListenAddress)
   cmo.setListenPort(nodeManagerPort)

   # Clone machine name
   originalManagedServerName = 'essbase_server1'

   print 'Adding Essbase server ' + managedServerName

   ### Clone the managed server
   cd('/')
   clone(originalManagedServerName, managedServerName, 'Server') 

   # Port setup for the managed server
   cd('/Server/' + managedServerName)
   if managedServerListenAddress is not None:
      cmo.setListenAddress(managedServerListenAddress)
   else:
      cmo.setListenAddress('')

   if managedServerPort is not None:
      cmo.setListenPort(int(managedServerPort))

   try:
      cd('/Server/' + managedServerName + '/SSL/' + originalManagedServerName)
      set('Name', managedServerName)
   except:
      pass

   try:
      cd('/Server/' + managedServerName + '/SSL/' + managedServerName)
      enabled = cmo.getEnabled()
      cmo.setEnabled(True)
      if managedServerSslPort is not None:
         cmo.setListenPort(int(managedServerSslPort))
      cmo.setEnabled(enabled)
   except:
      pass

   try:
      cd('/Server/' + managedServerName)
      cd('WebServer/' + originalManagedServerName)
      set('Name', managedServerName)
      cd('WebServerLog/' + originalManagedServerName)
      set('Name', managedServerName)
   except:
      pass

   try:
      cd('/Server/' + managedServerName)
      cd('ServerDiagnosticConfig/' + originalManagedServerName)
      set('Name', managedServerName)
   except:
      pass

   # Assign server to provided machine 
   assign('Server', managedServerName, 'Machine', machineName)

   print "Updating domain..."
   updateDomain()
   closeDomain()

   print "Essbase managed server " + managedServerName + " added and assigned to " + machineName

except:
   dumpStack()
   raise
