# Copyright (C) 2017, CERN
# This software is distributed under the terms of the GNU General Public
# License version 3 (GPL Version 3), copied verbatim in the file "LICENSE".
# In applying this license, CERN does not waive the privileges and immunities
# granted to it by virtue of its status as Intergovernmental Organization
# or submit itself to any jurisdiction.
#
# WebLogic on Docker Basic Server Domain
#
# Domain, as defined in DOMAIN_NAME, will be created in this script. Name defaults to 'base_domain'.
#
# Since : November, 2017
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
# Starting at 12.2.1 the good and old readTemplate and addTemplate() commands have been deprecated
# See https://blogs.oracle.com/oraclewebcentersuite/changes-to-some-wlst-commands-in-1221
selectTemplate("Basic WebLogic Server Domain","12.2.1.0.0")
loadTemplates()

set('Name', domain_name)
setOption('DomainName', domain_name)

# Configure the Administration Server.
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
setOption('ServerStartMode', production_mode)


# Write Domain
# ============
writeDomain(domain_path)
closeTemplate()

# Exit WLST
# =========
exit()
