#!/bin/bash

function usage() {
  echo "Usage: "
  echo "  ${0} [dep name] [port] [type]"
  echo "    dep name  : Deployment name     ( default is hello-world-backend )"
  echo "    port      : Deployment port     ( default is 8080 )"
  echo "    proto     : Deployment protocol ( default is http )"
  exit 1
}

if [ $# -ne 3 ] && [ $# -ne 0 ]; then
  usage
fi  

if [ $# -eq 0 ]; then
  DEPNAME="hello-world-backend"
  PORT="8080"
  PROTO="http"
else    
  DEPNAME=${1}
  PORT=${2}
  PROTO=${3}
fi  

function checkExposed() {
  EXISTS=$(skupper list-exposed | grep ${DEPNAME} | grep port | awk -F " " '{print $1}')
  if [ "${EXISTS}" == "${DEPNAME}" ]; then
    echo "${DEPNAME}"
  else
    echo ""
  fi
}

echo "[] Checking if the deployment ${DEPNAME} is already exposed"
CHECKDEPLOY=$(checkExposed)
if [ "${CHECKDEPLOY}" == "${DEPNAME}" ]; then
  echo "  => Deployment ${DEPNAME} already exposed"
else
  echo "  => Exposing it"
  skupper expose deployment ${DEPNAME} --port ${PORT} --protocol ${PROTO}
  CHECKEXPOSE=$(checkExposed)
  if [ "${CHECKEXPOSE}" == "${DEPNAME}" ]; then
    echo "    => Deployment ${DEPNAME} exposed"
  else
    echo "    => Unable to expose Deployment ${DEPNAME}. Check it manually"
  fi     
fi

