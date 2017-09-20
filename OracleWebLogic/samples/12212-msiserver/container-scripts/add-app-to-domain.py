domain_path  = sys.argv[1]
number_of_ms = int(sys.argv[2])
app_name = sys.argv[3]
app_location = sys.argv[4]
ms_name_prefix = sys.argv[5]

print('domain_path     : [%s]' % domain_path);
print('app_name     : [%s]' % app_name);
print('app_location     : [%s]' % app_location);
print('number_of_ms     : [%s]' % number_of_ms);
print('ms_name_prefix     : [%s]' % ms_name_prefix);

# Open default domain template
# ======================
readDomain(domain_path)

# Configure App
# =============
cd('/')
create(app_name, 'AppDeployment')
cd('/AppDeployments/%s/' % app_name)
set('StagingMode', 'nostage')
set('SourcePath', app_location)
targets = ms_name_prefix + str(1)
for index in range(2, number_of_ms + 1):
  targets = targets + ',%s' % (ms_name_prefix + str(index))
set('Target', targets)

# Write Domain
# ============
updateDomain()

# Exit WLST
# =========
exit()
