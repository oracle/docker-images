#!/bin/sh
#
# Start tlisten in the specified ports on the host's network address
#
# Usage:  start_tlisten nlsaddr_port  jmx_port
#
# Author: Todd Little
#
HOSTNAME=`hostname`
source $TUXDIR/tux.env
$TUXDIR/bin/tlisten -l "//$HOSTNAME:$1" -j "rmi://$HOSTNAME:$2"

