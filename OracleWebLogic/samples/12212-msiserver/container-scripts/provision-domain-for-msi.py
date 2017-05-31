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

# Open default domain template
# ======================
readTemplate(template_location)

set('Name', domain_name)
setOption('DomainName', domain_name)

# Disable Admin Console
# --------------------
cmo.setConsoleEnabled(false)

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
sys.stdout.write('Creating %s servers' % number_of_ms)
sys.stdout.flush()
for index in range(1, number_of_ms + 1):
  cd('/')
  sys.stdout.write('.')
  sys.stdout.flush()
  create('ms%s' % index, 'Server')
  cd('/Servers/ms%s/' % index )
  set('ListenPort', ms_port)
  set('NumOfRetriesBeforeMSIMode', 0)
  set('RetryIntervalBeforeMSIMode', 1)
print 'Done'

# Write Domain
# ============
writeDomain(domain_path)
closeTemplate()

# Exit WLST
# =========
exit()
