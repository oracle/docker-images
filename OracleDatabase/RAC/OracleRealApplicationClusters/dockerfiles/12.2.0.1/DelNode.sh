#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2018
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com
# Description: Delete  a Grid node and add Oracle Database instance.
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

declare -a cluster_nodes
DEL_NODE=${1}
NODE_HOSTNAME=$(hostname)

check_env_vars ()
{

if [ -z ${DEL_NODE} ];then
echo "Please provide node name which you want to delete";
exit 1;
else
echo "Deleting node name set to ${DEL_NODE}"
fi
}

containsNode () {
local nodes match="$1"
  shift
nodes=$1
for e in "${cluster_nodes[@]}"
do
 [[ "$e" == "$match" ]] && return 0;
done
return 1
}

setNode () {
cluster_nodes=( $($GRID_HOME/bin/olsnodes | awk '{ print $1 }') )
node_count=$($GRID_HOME/bin/olsnodes -a | awk '{ print $1 }' | wc -l)
}

delNode () {
echo "Checking if node exist in the cluster or not!"
containsNode "${DEL_NODE}"  "${cluster_nodes[@]}"
ret=$?

if [ $ret -eq 1 ]; then
echo "Node ${DEL_NODE} is not a part of cluster. These Nodes are part of the cluster $cluster_nodes"
exit 1 ;
fi

 if [ ${node_count} -eq 1 -a ${DEL_NODE} == ${NODE_HOSTNAME} ] ;then
  echo "Stopping the Grid and deconfigure the cluster."
  $GRID_HOME/bin/crsctl stop cluster
  $GRID_HOME/crs/install/rootcrs.sh -deconfig -force
 fi

echo "Stopping Grid on deleting node"
cmd='su - grid -c "ssh ${DEL_NODE} \"sudo ${GRID_HOME}/bin/crsctl stop cluster\""'
eval $cmd

echo "Deleting the node from the cluster"
$GRID_HOME/bin/crsctl delete node -n ${DEL_NODE}

echo "Checking if node exist in the cluster or not!"
containsNode "${DEL_NODE}"  "${cluster_nodes[@]}"
ret=$?

if [ $ret -eq 1 ]; then
echo "Node ${DEL_NODE} is not a part of cluster. These Nodes are part of the cluster $cluster_nodes"
exit 0 ;
else
echo "Node ${DEL_NODE} is still a part of cluster."
exit 1;
fi
}


##########################################
############# MAIN#########################
###########################################
check_env_vars
setNode
delNode
