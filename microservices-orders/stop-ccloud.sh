#!/bin/bash

# Source library 
source ../utils/helper.sh
source ../utils/ccloud_library.sh

# ./scripts/kill-services.sh .microservices.pids 2> /dev/null
# rm .microservices.pids 2> /dev/null
# confluent local destroy 2> /dev/null
# 
# # This is used in the services
# rm -fr /tmp/kafka-streams 2> /dev/null

# Destroy Confluent Cloud resources
if [ -z "$1" ]; then
  echo "ERROR: Must supply argument that is the client configuration file created from './start-ccloud.sh'. (Is it in stack-configs/ folder?) "
  exit 1
else
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
  CONFIG_FILE=${DIR}/$1
  ../ccloud/ccloud-stack/ccloud_stack_destroy.sh $CONFIG_FILE
fi
