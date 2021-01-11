#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This script updates the domain specific for the container environment.

import os
import sys
from __builtin__ import False

# Disable ls() output
WLS.setShowLSResult(0)

def noneIfNoValue(v):
   if v is None or v == 'NO_VALUE':
      return None
   return v

try:
   if len(sys.argv) < 2:
      print 'Expected number of arguments not passed!!'
      sys.exit(1)

   domainHome=sys.argv[1]
   domainName=os.path.basename(domainHome)
   
   print "Updating Essbase domain with container-specific configuration"
   readDomain(domainHome)

   # Get some lists for later
   cd('/Clusters')
   clusters = ls(returnMap='true')

   cd('/Servers')
   servers = ls(returnMap='true')

   cd('/StartupGroupConfig')
   startupGroupsConfigs = ls(returnMap='true')

   # Set internal apps to deploy on demand
   cd('/')
   set('InternalAppsDeployOnDemandEnabled', 'True')

   # Update nodemanager config
   cd('/NMProperties')
   set('CrashRecoveryEnabled', 'false')

   # Update the essbase server template
   cd('/ServerTemplate/essbase_server_template')
   set('NumOfRetriesBeforeMSIMode', 0)
   set('RetryIntervalBeforeMSIMode', 1)

   # Update the EAS server 
   if 'eas_server1' in servers:
      cd('/Servers/eas_server1')
      set('NumOfRetriesBeforeMSIMode', 0)
      set('RetryIntervalBeforeMSIMode', 1) 

   # Update the coherence settings
   clusterNames = []
   for k in clusters:
      cd('/Clusters/' + k)
      cmo.setClusterMessagingMode('unicast')
      set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
      clusterNames.append(k)

   for k in servers:
      cd('/Servers/' + k)
      set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')

   cd('/CoherenceClusterSystemResource/defaultCoherenceCluster')
   set('Target', ",".join(clusterNames))

   # Update the required startup properties for the admin server
   cd('/StartupGroupConfig')
   cd('AdminServerStartupGroup')
   dictionary = get('SystemProperties')
   dictionary['java.io.tmpdir'] = '${TMP_DIR}'
   dictionary['oracle.jdbc.fanEnabled'] = 'false'
   set('SystemProperties', dictionary)

   set('InitialHeapSize', '512')
   set('MaxHeapSize', '1024')

   # Update the required startup properties for the managed servers
   cd('/StartupGroupConfig')
   cd('ESSBASE-MAN-SVR')
   dictionary = get('SystemProperties')
   dictionary['DISCOVERY_URL'] = '${DISCOVERY_URL}'
   dictionary['java.io.tmpdir'] = '${TMP_DIR}'
   dictionary['oracle.jdbc.fanEnabled'] = 'false'
   set('SystemProperties', dictionary)

   dictionary = get('EnvVars')
   if 'COMMON_COMPONENTS_HOME' in dictionary:
     del dictionary['COMMON_COMPONENTS_HOME']

   if 'LD_LIBRARY_PATH' in dictionary:
     del dictionary['LD_LIBRARY_PATH']
   set('EnvVars', dictionary)
   
   # Update the required startup properties for the eas server
   if 'ESSBASE-EAS-SVR' in startupGroupsConfigs:
   
      cd('/StartupGroupConfig')
      cd('ESSBASE-EAS-SVR')
      dictionary = get('SystemProperties')
      dictionary['DISCOVERY_URL'] = '${DISCOVERY_URL}'
      dictionary['java.io.tmpdir'] = '${TMP_DIR}'
      dictionary['oracle.jdbc.fanEnabled'] = 'false'
      set('SystemProperties', dictionary)

      dictionary = get('EnvVars')
      if 'COMMON_COMPONENTS_HOME' in dictionary: 
         del dictionary['COMMON_COMPONENTS_HOME']
 
      if 'LD_LIBRARY_PATH' in dictionary:
         del dictionary['LD_LIBRARY_PATH']
      set('EnvVars', dictionary)

   updateDomain()
   closeDomain()

except:
   dumpStack()
   raise
