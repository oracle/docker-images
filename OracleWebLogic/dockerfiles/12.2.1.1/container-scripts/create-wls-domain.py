# Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
# WebLogic on Docker Default Domain
#
# Domain, as defined in DOMAIN_NAME, will be created in this script. Name defaults to 'base_domain'.
#
# Since : October, 2014
# Author: bruno.borges@oracle.com
# ==============================================
domain_name  = os.environ.get("DOMAIN_NAME", "base_domain")
admin_port   = int(os.environ.get("ADMIN_PORT", "7001"))
admin_pass   = "ADMIN_PASSWORD"
domain_path  = '/u01/oracle/user_projects/domains/%s' % domain_name
production_mode = os.environ.get("PRODUCTION_MODE", "prod")

print('domain_name : [%s]' % domain_name);
print('admin_port  : [%s]' % admin_port);
print('domain_path : [%s]' % domain_path);
print('production_mode : [%s]' % production_mode);

# Open default domain template
# ======================
readTemplate("/u01/oracle/wlserver/common/templates/wls/wls.jar")

set('Name', domain_name)
setOption('DomainName', domain_name)

# Disable Admin Console
# --------------------
# cmo.setConsoleEnabled(false)

# Configure the Administration Server and SSL port.
# =========================================================
cd('/Servers/AdminServer')
set('ListenAddress', '')
set('ListenPort', admin_port)

# Define the user password for weblogic
# =====================================
cd('/Security/%s/User/weblogic' % domain_name)
cmo.setPassword(admin_pass)

# Write the domain and close the domain template
# ==============================================
setOption('OverwriteDomain', 'true')
setOption('ServerStartMode',production_mode)

cd('/NMProperties')
set('ListenAddress','')
set('ListenPort',5556)
set('CrashRecoveryEnabled', 'true')
set('NativeVersionEnabled', 'true')
set('StartScriptEnabled', 'false')
set('SecureListener', 'false')
set('LogLevel', 'FINEST')

# Set the Node Manager user name and password (domain name will change after writeDomain)
cd('/SecurityConfiguration/base_domain')
set('NodeManagerUsername', 'weblogic')
set('NodeManagerPasswordEncrypted', admin_pass)

# Write Domain
# ============
writeDomain(domain_path)
closeTemplate()

# Exit WLST
# =========
exit()
