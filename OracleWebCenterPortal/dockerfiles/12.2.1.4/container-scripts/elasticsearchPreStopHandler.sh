#!/bin/bash
# Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
export vol_name=u01
export ES_NODE_NAME=$NODE_NAME
export ES_NODE_DIR="/$vol_name/esHome/esNode/$ES_NODE_NAME"
export ES_STOP_SCRIPT="/$vol_name/esHome/stopElasticsearch.sh"

echo "Deleting Elasticsearch folder on FSS: $ES_NODE_DIR"
$ES_STOP_SCRIPT
sleep 5
rm -rf $ES_NODE_DIR
