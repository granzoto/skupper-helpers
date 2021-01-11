#!/bin/bash

CMDINIT=""
MSGTUNNEL=""
MSGCONSOLE=""
if [ "${1}" == "tunnel" ] || [ "${2}" == "tunnel" ]; then
  echo "Staring iminikube tunnel before starting skupper"
  nohup minikube tunnel &
  CMDINIT="skupper init "
else  
  CMDINIT="skupper init --cluster-local"
  MSGTUNNEL=" with --cluster-local."
fi

if [ "${1}" == "console" ] || [ "${2}" == "console" ]; then
  CMDINIT="${CMDINIT} --enable-console --console-auth unsecured"
  MSGCONSOLE="Using --enable-console --console-auth unsecured"
fi    

echo "[] Check if skupper is already installed"
skupper status

if [ "${?}" -eq 0 ]; then
  echo "  => Skupper is already installed in this namespace"
else
  echo "  => Skupper is not installed in this namespace yet"
  echo "  => Installing skupper ${MSGTUNNEL}${MSGCONSOLE}"
  ${CMDINIT}
fi  
