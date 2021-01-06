# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#

# autoinstall.cfg for the UCM instance
#
# autoinstall.cfg is used to avoid the need to restart the Content Server after
# making changes on the post install config page in 11g for UCM/IBR topologies.
# After install and before startup of managed server.
# The content server will read in this file at next start up and merge in the configuration
# and will look for certain entries that tell it to enable certain components.

IDC_Name=@INSTALL_HOST_NAME@@UCM_PORT@
InstanceMenuLabel=@INSTALL_HOST_NAME@@UCM_PORT@
InstanceDescription=Instance @INSTALL_HOST_NAME@@UCM_PORT@
HttpServerAddress=@INSTALL_HOST_FQDN@:@UCM_PORT@
MailServer=mail.oracle.com
SysAdminAddress=first.last@oracle.com

# prefix has to be less than 15 chars so just have it as the host and port
AutoNumberPrefix=@HOST_NAME_PREFIX@
IsAutoNumber=true

# Intradoc port and filter
IntradocServerPort.UCM_server1=@UCM_INTRADOC_PORT@
SocketHostAddressSecurityFilter=127.0.0.1|0:0:0:0:0:0:0:1|*.*.*.*

# Complete install
--------------------------------------------
# Needed to indicate the autoinstall is complete, if you miss this off
# You will still get the configuration screen
AutoInstallComplete=true
