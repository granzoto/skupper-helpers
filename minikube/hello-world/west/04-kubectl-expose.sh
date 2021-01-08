#!/bin/bash

function usage() {
  echo "Usage: "
  echo "  ${0} [dep name] [port] [type]"
  echo "    dep name  : Deployment name  ( default is hello-world-frontend )"
  echo "    port      : Deployment port  ( default is 8080 )"
  echo "    type      : Deployment type  ( default is LoadBalancer )"
  exit 1
}

if [ $# -ne 3 ] && [ $# -ne 0 ]; then
  usage
fi  

if [ $# -eq 0 ]; then
  DEPNAME="hello-world-frontend"
  PORT="8080"
  TYPE="LoadBalancer"
else    
  DEPNAME=${1}
  PORT=${2}
  TYPE=${3}
fi  

function checkExposed() {
  EXISTS=$(kubectl get service ${DEPNAME} --no-headers | awk -F " " '{print $1}')
  if [ "${EXISTS}" == "${DEPNAME}" ]; then
    echo "${DEPNAME}"
  else
    echo ""
  fi
}

echo "[] Checking if the deployment ${DEPNAME} already exposed"
CHECKDEPLOY=$(checkExposed)
if [ "${CHECKDEPLOY}" == "${DEPNAME}" ]; then
  echo "  => Deployment ${DEPNAME} already exposed"
else
  echo "  => Exposing it"
  kubectl expose deployment ${DEPNAME} --port ${PORT} --type ${TYPE}
  CHECKEXPOSE=$(checkExposed)
  if [ "${CHECKEXPOSE}" == "${DEPNAME}" ]; then
    echo "    => Deployment ${DEPNAME} exposed"
  else
    echo "    => Unable to expose Deployment ${DEPNAME}. Check it manually"
  fi     
fi

