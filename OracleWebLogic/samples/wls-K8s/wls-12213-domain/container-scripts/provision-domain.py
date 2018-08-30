#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#Provision a WebLogic Domain

import sys

domain_name  = sys.argv[1]
template_location = sys.argv[2]
domain_path  = sys.argv[3] + '/%s' % domain_name
user_name = sys.argv[4]
password = sys.argv[5]
as_port = int(sys.argv[6])
ms_name = sys.argv[7]
ms_port = int(sys.argv[8])
production_mode = sys.argv[9]
number_of_ms = int(sys.argv[10])
cluster_name = sys.argv[11]
dns_domain_name = sys.argv[12]

print('domain_name     : [%s]' % domain_name);
print('template_location     : [%s]' % template_location);
print('domain_path     : [%s]' % domain_path);
print('user_name     : [%s]' % user_name);
print('password     : ********');
print('as_port      : [%s]' % as_port);
print('ms_name     : [%s]' % ms_name);
print('ms_port     : [%s]' % ms_port);
print('production_mode : [%s]' % production_mode);
print('number_of_ms : [%s]' % number_of_ms);
print('cluster_name : [%s]' % cluster_name);
print('dns_domain_name : [%s]' % dns_domain_name);

# Open default domain template
# ======================
readTemplate(template_location)

set('Name', domain_name)
setOption('DomainName', domain_name)

# Disable Admin Console
# --------------------
#cmo.setConsoleEnabled(false)
cmo.setConsoleEnabled(true)

# Configure the Administration Server and SSL port.
# =========================================================
cd('/Servers/AdminServer')
set('ListenPort', as_port)

# Define the user password for weblogic
# =====================================
cd(('/Security/%s/User/' + user_name) % domain_name)
cmo.setPassword(password)

# Write the domain and close the domain template
# ==============================================
setOption('OverwriteDomain', 'true')
setOption('ServerStartMode',production_mode)

# Create Server & set MSI configuration
# =====================================
cd('/')
create(cluster_name, 'Cluster')
sys.stdout.write('Creating %s servers' % number_of_ms)
sys.stdout.flush()
for index in range(0, number_of_ms):
  cd('/')
  sys.stdout.write('.')
  sys.stdout.flush()
  name = 'ms-%s' % index
  create(name, 'Server')
  cd('/Servers/ms-%s/' % index )
  listenAddress = '%s.%s.default.svc.cluster.local' % (name, dns_domain_name)
  print('ms name is %s' % name);
  print('listenAddress to %s' % listenAddress);
  set('ListenAddress', listenAddress)
  set('ListenPort', ms_port)
  set('NumOfRetriesBeforeMSIMode', 0)
  set('RetryIntervalBeforeMSIMode', 1)
  set('Cluster', cluster_name)
print 'Done'

# Write Domain
# ============
writeDomain(domain_path)
closeTemplate()

# Exit WLST
# =========
exit()
