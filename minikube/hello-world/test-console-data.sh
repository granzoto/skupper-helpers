#!/bin/bash
CON_URL="http://10.98.41.194:8080"
APP_URL="http://0.0.0.0:8090"

echo "Starting Console test"

echo "Retrieving details from Skupper console"
DATA=$(curl -s ${CON_URL}/DATA | jq '.services[].requests_received[].by_client[] | {"requests": .requests, "bytes_in": .bytes_in, "bytes_out": .bytes_out}')
REQ_OLD=$(echo $DATA | jq '.requests')
BIN_OLD=$(echo $DATA | jq '.bytes_in')
BOUT_OLD=$(echo $DATA | jq '.bytes_out')

echo "Old Request  ==> ${REQ_OLD}"
echo "Old BytesIN  ==> ${BIN_OLD}"
echo "Old BytesOut ==> ${BOUT_OLD}"

echo "Retrieving details from Skupper console"
curl -s ${APP_URL}


echo "Retrieving details from Skupper console again"
DATA=$(curl -s ${CON_URL}/DATA | jq '.services[].requests_received[].by_client[] | {"requests": .requests, "bytes_in": .bytes_in, "bytes_out": .bytes_out}')
REQ_NEW=$(echo $DATA | jq '.requests')
BIN_NEW=$(echo $DATA | jq '.bytes_in')
BOUT_NEW=$(echo $DATA | jq '.bytes_out')

echo "New Request  ==> ${REQ_NEW}"
echo "New BytesIN  ==> ${BIN_NEW}"
echo "New BytesOut ==> ${BOUT_NEW}"
