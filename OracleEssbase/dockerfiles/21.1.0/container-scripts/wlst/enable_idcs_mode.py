#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl.
#

# This script updates the Essbase domain with IDCS configuration settings in offline mode

import os
import socket
import sys
import shutil

def noneIfNoValue(v):
   if v is None or v == 'NO_VALUE':
      return None
   return v

try:
   if len(sys.argv) < 8:
      print 'Expected number of arguments not passed!!'
      sys.exit(1)

   domainHome=sys.argv[1]
   domainName=os.path.basename(domainHome)
    
   idcsHost=sys.argv[2]
   idcsPort=int(sys.argv[3])
   idcsServerCertificate=noneIfNoValue(sys.argv[4])
   idcsTenant=sys.argv[5]
   idcsClientTenant=noneIfNoValue(sys.argv[6])
   idcsClientId=sys.argv[7]
    
   # More secure...avoids the command line and env variables
   idcsClientSecret=sys.stdin.readline()
   idcsClientSecret=idcsClientSecret.strip()

   # This is required due to bug OWLS-71636
   idcsClientSecretEncrypted=encrypt(idcsClientSecret, domainHome)

   print 'Enabling IDCS provider for tenant ' + idcsTenant
   readDomain(domainHome)
    
   print 'Applying OPSS SCIM Identity Store template...'
   selectTemplate("Oracle OPSS SCIM Identity Store")

   if idcsServerCertificate is not None:
      print 'Applying OPSS IDCS Server Certificate template...'
      selectTemplate("Oracle OPSS IDCS Server Certificate")
    
   loadTemplates()
    
   if idcsServerCertificate is not None:
      cd("/Keystore/TargetStore/system/TargetKey/trust/TrustCertificate/idcs_server_cert")
      set("Location", idcsServerCertificate)
    
   cd("/SecurityConfiguration/%s" % domainName)
   rlname=cmo.getDefaultRealm().getName()
   cd("Realm/%s" % rlname)
   create('IdentityCloudServiceIntegrator', 'weblogic.security.providers.authentication.OracleIdentityCloudIntegrator', 'AuthenticationProvider')
    
   cd('AuthenticationProviders/IdentityCloudServiceIntegrator')
    
   set('Host', idcsHost)
   set('Port', idcsPort)
   set('SSLEnabled', true)
   set('Tenant', idcsTenant)
   if idcsClientTenant is not None:
      set('ClientTenant', idcsClientTenant)
   set('ClientId', idcsClientId)
   set('ClientSecretEncrypted', idcsClientSecretEncrypted)
   set('ActiveTypes', [ 'idcs_user_assertion', 'Idcs_user_assertion', 'Authorization' ])
   set('ResponseReadTimeout', 300)
   set('CacheSize', 102400)
   set('ControlFlag', 'SUFFICIENT')
    
   cd('..')
   cd('DefaultAuthenticator')
   set('ControlFlag', 'SUFFICIENT')
    
   # When an HTTP request is processed by the WebLogic Server container, there may be multiple matches that can be used for identity assertion. 
   # However, the provider can only consume one active token type at a time. As a result there is no way to provide a set of tokens that can be consumed with one call. 
   # Therefore, the WebLogic Server container must choose between multiple tokens to perform identity assertion. The order for the same set here.
   cd("/SecurityConfiguration/%s" % domainName)
   cd("Realm/%s" % rlname)
   cmo.setIdentityAssertionHeaderNamePrecedence(["Authorization: Bearer","idcs_user_assertion","Idcs_user_assertion"])
   
   logoutUrl = "/essbase/redirect_uri?logout=" 

   # Update the required system properties for the managed server
   cd('/StartupGroupConfig')
   cd('ESSBASE-MAN-SVR')
   dictionary = get('SystemProperties')
   dictionary['LOGOUT_URL'] = logoutUrl
   set('SystemProperties', dictionary)
    
   updateDomain()
   closeDomain()
    
except:
   dumpStack()
   raise
