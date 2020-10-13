# # Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
# #
# # Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# #
# # Author: OIM Development (<raminder.deep.kaler@oracle.com>)
# #
import os,sys
import time as st
#The following need to be externalized, i.e., passed to the py script which invocation
WLS_ADMIN_USER=sys.argv[1]
WLS_ADMIN_PWD=sys.argv[2]
oimhost=sys.argv[3]
oimport=sys.argv[4]
adminhost=sys.argv[5]
adminport=sys.argv[6]

#This has to be the t3 url of oim admin server
WLS_T3_URL='t3://'+adminhost+':'+adminport
#oim frontend url
OIM_FE_URL='http://'+oimhost+':'+ oimport
#oim external frontend url
OIM_EXT_FE_URL='http://'+adminhost+':' + oimport

#connect to the oim admin server's runtime mbean server
connect(WLS_ADMIN_USER, WLS_ADMIN_PWD, WLS_T3_URL)

domainRuntime()
print("entering for loop")
i=0
while i<10:
	i=i+1
	try:
		print("trying to invoke mbean")
		msBean = ObjectName('oracle.iam:Location=oim_server1,name=OIMSOAIntegrationMBean,type=IAMAppRuntimeMBean,Application=oim')
		params = [WLS_ADMIN_USER, WLS_ADMIN_PWD, OIM_FE_URL, OIM_EXT_FE_URL]
		sign = ['java.lang.String', 'java.lang.String','java.lang.String', 'java.lang.String' ]
		mbs.invoke(msBean, 'integrateWithSOAServer', params, sign)
		print("successfully executed OIM SOA Integration Mbean")
		break
	except:
		st.sleep(120)
		print("command failed, will try again")
		if i<9:
			pass
		else:
			print("Failed to connect to oim mbeans after waiting for 20 Mins, please check your applications")
			raise
		continue
disconnect()

