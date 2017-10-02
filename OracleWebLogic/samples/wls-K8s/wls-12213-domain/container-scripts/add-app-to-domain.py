#Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Deploy application to the WebLogic Cluster and define WLDF policy
#

domain_path = sys.argv[1]
target_name = sys.argv[2]
as_name = sys.argv[3]

print('domain_path     : [%s]' % domain_path);
print('target_name     : [%s]' % target_name);
print('as_name         : [%s]' % as_name);

# Open default domain template
# ======================
readDomain(domain_path)

# Configure Apps
# ==============
index = 4
num_args = len(sys.argv)

while(index < num_args - 1):
  app_name = sys.argv[index]
  index = index + 1
  app_location = sys.argv[index]
  index = index + 1
  if (app_name != None and app_location != None):
    print('Configuring:');
    print('  app_name         : [%s]' % app_name);
    print('  app_location     : [%s]' % app_location);
    cd('/')
    create(app_name, 'AppDeployment')
    cd('/AppDeployments/%s/' % app_name)
    if (app_location.endswith('.war')):
      set('ModuleType', 'war')
    set('StagingMode', 'nostage')
    set('SourcePath', app_location)
    set('Target', target_name)

# Configure WLDF
# ============-=
print('Configuring WLDF system resource');
cd('/')

create('Module-0','WLDFSystemResource')
cd('/WLDFSystemResources/Module-0')
set('DescriptorFileName', 'diagnostics/Module-0-3905.xml')

cd('/')
assign('WLDFSystemResource', 'Module-0', 'Target', as_name)

# Write Domain
# ============
print('Updating domain')
updateDomain()

# Exit WLST
# =========
exit()
