#!/bin/bash

# Source library
source ../utils/ccloud_library.sh
source ../utils/helper.sh

ccloud::validate_version_ccloud_cli 1.10.0 \
  && print_pass "ccloud version ok"

ccloud::validate_logged_in_ccloud_cli \
  && print_pass "logged into ccloud CLI"

echo
echo ====== Create new Confluent Cloud stack
[[ -z "$NO_PROMPT" ]] && ccloud::prompt_continue_ccloud_demo
REPLICATION_FACTOR=3 ccloud::create_ccloud_stack true

SERVICE_ACCOUNT_ID=$(ccloud kafka cluster list -o json | jq -r '.[0].name' | awk -F'-' '{print $4;}')
if [[ "$SERVICE_ACCOUNT_ID" == "" ]]; then
  echo "ERROR: Could not determine SERVICE_ACCOUNT_ID from 'ccloud kafka cluster list'. Please troubleshoot, destroy stack, and try again to create the stack."
  exit 1
fi
export CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config

echo "====== Generating Confluent Cloud configurations"
../ccloud/ccloud-generate-cp-configs.sh $CONFIG_FILE
 
DELTA_CONFIGS_DIR=delta_configs
source $DELTA_CONFIGS_DIR/env.delta

echo "====== Creating demo topics"
./scripts/create-topics-ccloud.sh ./topics.txt

docker-compose -f docker-compose-ccloud.yml up -d --build 

# export CONFIG_FILE=$CONFIG_FILE
# ccloud::validate_ccloud_config $CONFIG_FILE \
#   && print_pass "$CONFIG_FILE ok" \
#   || exit 1


# confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:latest
# confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:latest
# grep -qxF 'auto.offset.reset=earliest' $CONFLUENT_HOME/etc/ksqldb/ksql-server.properties || echo 'auto.offset.reset=earliest' >> $CONFLUENT_HOME/etc/ksqldb/ksql-server.properties 
# confluent local start
# sleep 5
# 
# export BOOTSTRAP_SERVERS=localhost:9092
# export SCHEMA_REGISTRY_URL=http://localhost:8081
# export SQLITE_DB_PATH=${PWD}/db/data/microservices.db
# export ELASTICSEARCH_URL=http://localhost:9200
# 
# echo "Creating demo topics"
# ./scripts/create-topics.sh
# 
# echo "Setting up sqlite DB"
# (cd db; sqlite3 data/microservices.db < ./customers.sql)
# 
# echo "Configuring Elasticsearch and Kibana"
# ./dashboard/set_elasticsearch_mapping.sh
# ./dashboard/configure_kibana_dashboard.sh
# 
# echo ""
# echo "Submitting connectors"
# 
# # Kafka Connect to source customers from sqlite3 database and produce to Kafka topic "customers"
# INPUT_FILE=./connectors/connector_jdbc_customers_template.config 
# OUTPUT_FILE=./connectors/rendered-connectors/connector_jdbc_customers.config 
# source ./scripts/render-connector-config.sh
# confluent local config jdbc-customers -- -d $OUTPUT_FILE 2> /dev/null
# 
# # Sink Connector -> Elasticsearch -> Kibana
# INPUT_FILE=./connectors/connector_elasticsearch_template.config
# OUTPUT_FILE=./connectors/rendered-connectors/connector_elasticsearch.config
# source ./scripts/render-connector-config.sh
# confluent local config elasticsearch -- -d $OUTPUT_FILE 2> /dev/null
# 
# # Find an available local port to bind the REST service to
# FREE_PORT=$(jot -r 1  10000 65000)
# COUNT=0
# while [[ $(netstat -ant | grep "$FREE_PORT") != "" ]]; do
#   FREE_PORT=$(jot -r 1  10000 65000)
#   COUNT=$((COUNT+1))
#   if [[ $COUNT > 5 ]]; then
#     echo "Could not allocate a free network port. Please troubleshoot"
#     exit 1
#   fi
# done
# echo "Port $FREE_PORT looks free for the Orders Service"
# echo "Running Microservices"
# ( RESTPORT=$FREE_PORT JAR=$(pwd)"/kafka-streams-examples/target/kafka-streams-examples-$CONFLUENT-standalone.jar" scripts/run-services.sh > logs/run-services.log 2>&1 & )
# 
# echo "Waiting for data population before starting ksqlDB applications"
# sleep 150
# # Create ksqlDB queries
# ksql http://localhost:8088 <<EOF
# run script 'statements.sql';
# exit ;
# EOF
# 
# ./read-topics.sh
# 

