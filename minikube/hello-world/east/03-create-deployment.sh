#!/bin/bash

function usage() {
  echo "Usage: "
  echo "  ${0} [dep name] [dep image]"
  echo "    dep name  : Deployment name  ( default is hello-world-backend )"
  echo "    dep image : Deployment image ( default is quay.io/skupper/hello-world-backend )"
  exit 1
}

if [ $# -ne 2 ] && [ $# -ne 0 ]; then
  usage
fi  

if [ $# -eq 0 ]; then
  DEPNAME="hello-world-backend"
  DEPIMAGE="quay.io/skupper/hello-world-backend"
else    
  DEPNAME=${1}
  DEPIMAGE=${2}
fi  

function checkDeploy() {
  EXISTS=$(kubectl get deployment ${DEPNAME} --no-headers 2> /dev/null| awk -F " " '{print $1}')
  if [ "${EXISTS}" == "${DEPNAME}" ]; then
    echo "${DEPNAME}"
  else
    echo ""
  fi
}

function checkAvailable() {
  AVAILABLE=$(kubectl get deployment ${DEPNAME} --no-headers 2> /dev/null| awk -F " " '{print $2}')
  if [ "${AVAILABLE}" == "1/1" ]; then
    echo "OK"
  else
    echo ""
  fi
}
echo "[] Checking if the deployment ${DEPNAME} already exists"
CHECKDEPLOY=$(checkDeploy)
if [ "${CHECKDEPLOY}" == "${DEPNAME}" ]; then
  echo "  => Deployment ${DEPNAME} already exists"
else
  echo "  => Deploying it"
  kubectl create deployment ${DEPNAME} --image ${DEPIMAGE}
  CHECKDEPLOY=$(checkDeploy)
  if [ "${CHECKDEPLOY}" == "${DEPNAME}" ]; then
    echo "    => Deployment ${DEPNAME} created"
  else
    echo "    => Unable to create Deployment ${DEPNAME}. Check it manually"
  fi     
fi

echo "[] Checking f deployment ${DEPNAME} is available"
for count in $(seq 3); do
  CHECKAVAILABLE=$(checkAvailable)
  if [ "${CHECKAVAILABLE}" == "OK" ]; then
    echo "  => Deployment ${DEPNAME} is available"
    exit 0 
  else
    echo "      ...Waiting 5 seconds..."
    sleep 5
  fi  
done

echo "  => Deployment ${DEPNAME} is not available. Check manually"
