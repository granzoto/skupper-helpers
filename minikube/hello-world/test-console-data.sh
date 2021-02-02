#!/bin/bash
CON_URL="$1"
APP_URL="$2"

function usage() {
  echo "Usage: "
  echo "  ${0} [CON_URL] [APP_URL]"
  echo "    CON_URL : The URL to access Skupper Console"
  echo "    APP_URL : The URL to access FrontEnd application )"
  echo " "
  echo "  IMPORTANT : You can get both values in the output of the all-in-one-setup-test.sh script "
  echo " "
  exit 1
}

if [ $# -ne 2 ]; then
  usage
fi


echo "Starting Console test"

function test_console_available() {
    echo -e "\n==========================================="
    echo -e "==== Running test_console_available"
    echo -e "==========================================="
    echo "Checking is Skupper console is available"
    curl -s --connect-timeout 10 ${CON_URL} 2>&1> /dev/null
    if [ $? -ne 0 ]; then
        echo "The console is not available at ${CON_URL}"
        echo "Test test_console_available FAILED"
        exit 1
    fi
    echo "Test test_console_available PASSED"
    return 0
}    


function test_console_DATA_available() {
    echo -e "\n==========================================="
    echo -e "==== Running test_console_DATA_available"
    echo -e "==========================================="
    echo "Checking is /DATA is available on Skupper console"
    CURLDATA=$(curl -s --connect-timeout 10 ${CON_URL}/DATA)
    if echo $CURLDATA | grep -q "404"; then 
        echo "The path ${CON_URL}/DATA is not available"
        echo "Test test_console_DATA_available FAILED"
        exit 1
    fi
    echo "Test test_console_available PASSED"
    return 0
}    

function test_console_01() {

    let REQ_OLD=0
    let BIN_OLD=0
    let BOUT_OLD=0

    echo -e "\n==========================================="
    echo -e "==== Running test_console_01"
    echo -e "==========================================="
    echo "Retrieving details from Skupper console"

    DATAFULL=$(curl -s ${CON_URL}/DATA)
    REQVALID=$(echo ${DATAFULL} | jq -r '.services[].requests_received | select(.!=null)')
    if [ "${REQVALID}" != "" ] && [ "${REQVALID}" != "[]" ]; then
        DATA=$(echo ${DATAFULL} | jq '.services[].requests_received[].by_client[] | {"requests": .requests, "bytes_in": .bytes_in, "bytes_out": .bytes_out}')
        let REQ_OLD=$(echo $DATA | jq '.requests')
        let BIN_OLD=$(echo $DATA | jq '.bytes_in')
        let BOUT_OLD=$(echo $DATA | jq '.bytes_out')
    fi
    echo "Old Request  ==> ${REQ_OLD}"
    echo "Old BytesIN  ==> ${BIN_OLD}"
    echo "Old BytesOut ==> ${BOUT_OLD}"
 
    echo "Sending a request to the APP"
    curl -s ${APP_URL}

    echo "Retrieving details from Skupper console again"
 
    DATA=$(curl -s ${CON_URL}/DATA | jq '.services[].requests_received[].by_client[] | {"requests": .requests, "bytes_in": .bytes_in, "bytes_out": .bytes_out}')
    let REQ_NEW=$(echo $DATA | jq '.requests')
    let BIN_NEW=$(echo $DATA | jq '.bytes_in')
    let BOUT_NEW=$(echo $DATA | jq '.bytes_out')
    echo "New Request  ==> ${REQ_NEW}"
    echo "New BytesIN  ==> ${BIN_NEW}"
    echo "New BytesOut ==> ${BOUT_NEW}"
 
    let EACH_BYTES_IN=164
    let EACH_BYTES_OUT=206

    # Check if it has increased, but not check the exact value yet
    if [ ${REQ_NEW} -le ${REQ_OLD} ] || [ ${BIN_NEW} -le ${BIN_OLD} ] || [ ${BOUT_NEW} -le ${BOUT_OLD} ]; then
        echo "[Error 001] Data has not increased properly"
        echo "Test test_console_01 FAILED"
        exit 1
    fi
    echo "Test PASSED"
    return 0
}

function test_console_02() {

    let REQ_OLD=0
    let BIN_OLD=0
    let BOUT_OLD=0

    echo -e "\n==========================================="
    echo -e "==== Running test_console_02"
    echo -e "==========================================="
    echo "Retrieving details from Skupper console"

    DATAFULL=$(curl -s ${CON_URL}/DATA)
    REQVALID=$(echo ${DATAFULL} | jq -r '.services[].requests_received | select(.!=null)')
    if [ "${REQVALID}" != "" ] && [ "${REQVALID}" != "[]" ]; then
        DATA=$(echo ${DATAFULL} | jq '.services[].requests_received[].by_client[] | {"requests": .requests, "bytes_in": .bytes_in, "bytes_out": .bytes_out}')
        let REQ_OLD=$(echo $DATA | jq '.requests')
        let BIN_OLD=$(echo $DATA | jq '.bytes_in')
        let BOUT_OLD=$(echo $DATA | jq '.bytes_out')
    fi

    echo "Old Request  ==> ${REQ_OLD}"
    echo "Old BytesIN  ==> ${BIN_OLD}"
    echo "Old BytesOut ==> ${BOUT_OLD}"
 
    echo "Sending 5 request to the APP"
    curl -s ${APP_URL} 2>&1> /dev/null
    curl -s ${APP_URL} 2>&1> /dev/null
    curl -s ${APP_URL} 2>&1> /dev/null
    curl -s ${APP_URL} 2>&1> /dev/null
    curl -s ${APP_URL} 2>&1> /dev/null

    echo "Retrieving details from Skupper console again"
    DATA=$(curl -s ${CON_URL}/DATA | jq '.services[].requests_received[].by_client[] | {"requests": .requests, "bytes_in": .bytes_in, "bytes_out": .bytes_out}')
    let REQ_NEW=$(echo $DATA | jq '.requests')
    let BIN_NEW=$(echo $DATA | jq '.bytes_in')
    let BOUT_NEW=$(echo $DATA | jq '.bytes_out')
 
    echo "New Request  ==> ${REQ_NEW}"
    echo "New BytesIN  ==> ${BIN_NEW}"
    echo "New BytesOut ==> ${BOUT_NEW}"
 
    let EACH_BYTES_IN=164
    let EACH_BYTES_OUT=208

    let REQ_EXP=$(expr ${REQ_OLD} + 5)
    echo "Exp Request  ==> ${REQ_EXP}"

    # Check if the number of requests has increased by 5
    if [ ${REQ_NEW} -ne ${REQ_EXP} ]; then
        echo "[Error 001] Number of requests is incorrect"
        echo "Test test_console_02 FAILED"
        exit 1
    fi

    echo "Test PASSED"
    return 0
}

# Test if the console is available/can be reached
test_console_available

# Test if the /DATA path is available in the console
test_console_DATA_available

# Test if the values have increased
test_console_01

# Test number of requests after 5 requests 
test_console_02
