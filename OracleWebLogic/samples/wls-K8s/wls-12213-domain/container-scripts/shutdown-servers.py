#Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# Shutdown WebLogic Servers

host = sys.argv[1]
port = sys.argv[2]
user_name = sys.argv[3]
password = sys.argv[4]
name = sys.argv[5]

print('host     : [%s]' % host);
print('port      : [%s]' % port);
print('user_name     : [%s]' % user_name);
print('password     : ********');
print('name     : [%s]' % name);

connect(user_name, password, 't3://' + host + ':' + port)
shutdown(name, 'Server', ignoreSessions='true')
exit()
