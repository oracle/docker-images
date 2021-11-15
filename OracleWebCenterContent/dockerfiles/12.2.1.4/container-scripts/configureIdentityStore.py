#!/usr/bin/python
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#
# ==============================================
import sys

admin_name = os.environ['ADMIN_USERNAME']
admin_pass = os.environ['ADMIN_PASSWORD']
admin_port = os.environ['ADMIN_PORT']
admin_host = sys.argv[1]
configure_oid = sys.argv[2]
oid_host = sys.argv[3]
oid_port = sys.argv[4]
oid_pwd = sys.argv[5]
oid_auth_type = sys.argv[6]

print('Configuring Identity Store');
print('==========================');
print('Parameters :');
print('admin_host  :' +  admin_host );
print('Configure OID :' + configure_oid);
print('OID Host :' + oid_host);
print('OID Port :' + oid_port);
print('OID PWD  :' + oid_pwd);
print('OID Auth Type :' + oid_auth_type);
print('')
print('')

url = admin_host + ':' + admin_port
connect(admin_name, admin_pass, url)

edit()
startEdit()

print('Removing existing OIDAuthenticator if it already exists...')
cd('/SecurityConfiguration/base_domain/Realms/myrealm')
cmo.destroyAuthenticationProvider(getMBean('/SecurityConfiguration/base_domain/Realms/myrealm/AuthenticationProviders/OIDAuthenticator'))

activate()
startEdit()

print('Adding OIDAuthenticator...')
cmo.createAuthenticationProvider('OIDAuthenticator', 'weblogic.security.providers.authentication.OracleInternetDirectoryAuthenticator')

cd('/SecurityConfiguration/base_domain/Realms/myrealm/AuthenticationProviders/OIDAuthenticator')
cmo.setControlFlag('SUFFICIENT')

activate()
startEdit()

cmo.setPrincipal('cn=orcladmin')
cmo.setHost(oid_host)
cmo.setPort(int(oid_port))
cmo.setCredential(oid_pwd)
cmo.setGroupBaseDN('cn=groups,dc=us,dc=oracle,dc=com')
cmo.setUserBaseDN('cn=users,dc=us,dc=oracle,dc=com')

print('Setting to authenticate by uid...')
cmo.setAllUsersFilter('(&(' + oid_auth_type +'=*)(objectclass=person))')
cmo.setUserFromNameFilter('(&('+ oid_auth_type +'=%u)(objectclass=person))')
cmo.setUserNameAttribute(oid_auth_type)
cmo.setUseRetrievedUserNameAsPrincipal(true)

print('Amending DefaultAuthenticator')
cd('/SecurityConfiguration/base_domain/Realms/myrealm/AuthenticationProviders/DefaultAuthenticator')
cmo.setControlFlag('SUFFICIENT')

activate()

startEdit()

cd('/SecurityConfiguration/base_domain/Realms/myrealm')
set('AuthenticationProviders',jarray.array([ObjectName('Security:Name=myrealmOIDAuthenticator'), ObjectName('Security:Name=myrealmDefaultAuthenticator'), ObjectName('Security:Name=myrealmDefaultIdentityAsserter')], ObjectName))

save()
activate()

disconnect()
exit()

print('Identity Store configuration is done.');
