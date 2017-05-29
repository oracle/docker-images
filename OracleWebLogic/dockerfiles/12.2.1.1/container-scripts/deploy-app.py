import os
import sys

domainhome = os.environ.get('DOMAIN_HOME', '/u01/oracle/user_projects/domains/base_domain')

readDomain(domainhome)
appFile = sys.argv[1]
appName = os.path.splitext(appFile)[0]

app = create(appName, 'AppDeployment')
app.setSourcePath('/u01/oracle/'+appFile)
app.setStagingMode('nostage')
assign('AppDeployment', appName, 'Target', 'AdminServer')

updateDomain()
closeDomain()
exit()
