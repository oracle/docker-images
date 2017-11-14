# Copyright (c) 2017 CERN.
#
# WebLogic on Docker Default Domain
#
# Domain, as defined in DOMAIN_NAME, will be created in this script. Name defaults to 'base_domain'.
#
# Since : October, 2017
# Author: luis.rodriguez.fernandez@cern.ch
# ==============================================
domain_name  = os.environ.get("DOMAIN_NAME", "base_domain")
admin_port   = int(os.environ.get("ADMIN_PORT", "7001"))
admin_pass   = os.environ.get("ADMIN_PASSWORD")
domain_path  = '/u01/oracle/user_projects/domains/%s' % domain_name
production_mode         = os.environ.get("PRODUCTION_MODE", "dev")

print('domain_name : [%s]' % domain_name);
print('admin_port  : [%s]' % admin_port);
print('domain_path : [%s]' % domain_path);
print('production_mode : [%s]' % production_mode);

# Open default domain template
# ======================
readTemplate("/u01/oracle/wlserver/common/templates/wls/wls.jar")

set('Name', domain_name)
setOption('DomainName', domain_name)

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
setOption('ServerStartMode', 'dev')

# Write Domain
# ============
writeDomain(domain_path)
closeTemplate()

# Exit WLST
# =========
exit()
