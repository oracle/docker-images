# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

#
# This is an example of a WLST script to set FE Url
#


i = 1
while i < len(sys.argv):
    if sys.argv[i] == '-frontEndHost':
        frontEndHost = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-frontEndHttpPort':
        frontEndHttpPort = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-domainHome':
        domainHome = sys.argv[i + 1]
        i += 2
    else:
        print('Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i]))
        sys.exit(1)

print('front end host: ' + frontEndHost)
print('front end HTTP Port: ' + frontEndHttpPort)
frontEndURL = "http://" + frontEndHost + ":" + frontEndHttpPort
print('frontEndURL :' + frontEndURL)

## Setting Front End Host Port
readDomain(domainHome)
cd('/')
setFEHostURL(frontEndURL, "https://nohost:4455", "true")
updateDomain()
closeDomain()
exit()