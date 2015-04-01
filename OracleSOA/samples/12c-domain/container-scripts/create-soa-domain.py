DOMAIN_MODE='Compact'
DOMAIN_NAME='soa_domain'
DOMAIN_PATH='/u01/oracle/work/domains/' + DOMAIN_NAME
APP_PATH='/u01/oracle/work/app/' + DOMAIN_NAME
START_MODE='dev'

ADMIN_USERNAME='weblogic'
ADMIN_PASSWORD='welcome1'

DB_URL='jdbc:oracle:thin:@dbhost:49161:XE'
DB_REPO_PREFIX='DEVSOA'
DB_REPO_PASSWORD='welcome1'

print 'Creating Base Domain'

readTemplate('/u01/oracle/soa/wlserver/common/templates/wls/wls.jar', DOMAIN_MODE)

setOption('ServerStartMode', 'dev')
setOption('AppDir', APP_PATH)

cd('/Security/base_domain/User/weblogic')
set('Name', ADMIN_USERNAME)
cmo.setPassword(ADMIN_PASSWORD)

writeDomain(DOMAIN_PATH)
closeTemplate()

print 'Adding Templates'

readDomain(DOMAIN_PATH)

addTemplate('/u01/oracle/soa/osb/common/templates/wls/oracle.osb_template_12.1.3.jar')
addTemplate('/u01/oracle/soa/soa/common/templates/wls/oracle.soa_template_12.1.3.jar')

updateDomain()
closeDomain()

print('Domain Creation Completed')
exit()
