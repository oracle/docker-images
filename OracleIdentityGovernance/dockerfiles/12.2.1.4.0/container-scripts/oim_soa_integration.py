# Copyright (c) 2020, 2021 Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Author: OIG Development
#
import os,sys
import time as st
#The following need to be externalized, i.e., passed to the py script which invocation
WLS_ADMIN_USER=sys.argv[1]
WLS_ADMIN_PWD=sys.argv[2]
mbsurl=sys.argv[3]
oimurl=sys.argv[4]
soaurl=sys.argv[5]
umsurl=sys.argv[6]

#This has to be the t3 url of oim admin server
WLS_T3_URL='t3://' + mbsurl
#oim frontend url
OIM_FE_URL='http://' + oimurl
#oim external frontend url
OIM_EXT_FE_URL='http://' + oimurl
SOA_FRONTEND_URL='http://' + soaurl
SOA_T3_URL='t3://' + soaurl
UMS_URL='http://' + umsurl + '/ucs/messaging/webservice'


#connect to the oim admin server's runtime mbean server
connect(WLS_ADMIN_USER, WLS_ADMIN_PWD, WLS_T3_URL)
msBean = ObjectName('oracle.iam:name=OIMSOAIntegrationMBean,type=IAMAppRuntimeMBean,Application=oim')

mbeanInfo=mbs.getMBeanInfo(msBean)

params = [WLS_ADMIN_USER, WLS_ADMIN_PWD, OIM_FE_URL, OIM_EXT_FE_URL, SOA_FRONTEND_URL, SOA_T3_URL, UMS_URL]
sign = ['java.lang.String', 'java.lang.String','java.lang.String', 'java.lang.String', 'java.lang.String', 'java.lang.String' ,'java.lang.String' ]

for operation in mbeanInfo.getOperations():
	if operation.getName()=='integrateWithSOAServer' and len(operation.getSignature()) == 4:
		print("Found an older version of mbean with 4 attributes")
		params = [WLS_ADMIN_USER, WLS_ADMIN_PWD, OIM_FE_URL, OIM_EXT_FE_URL]
		sign = ['java.lang.String', 'java.lang.String','java.lang.String', 'java.lang.String']


domainRuntime()
print("entering for loop")
i=0
while i<10:
	i=i+1
	try:
		print("Trying to invoke mbean")
		mbs.invoke(msBean, 'integrateWithSOAServer', params, sign)
		print("Successfully executed OIMSOAIntegrationMbean")
		break
	except:
		st.sleep(120)
		print("Command failed, will try again")
		if i<9:
			pass
		else:
			print("Failed to connect to oim mbeans after waiting for 20 Mins, please check your applications")
			raise
		continue
disconnect()
