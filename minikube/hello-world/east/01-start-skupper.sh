#!/bin/bash

echo "[] Check if skupper is already installed"
skupper status
if [ "${?}" -eq 0 ]; then
  echo "  => Skupper is already installed in this namespace"
else
  echo "  => Skupper is not installed in this namespace yet, installing it"
  if [ "${1}" == "console" ] || [ "${2}" == "console" ]; then
    echo "    => Starting Skupper with console enabled"
    skupper init --cluster-local --enable-console --console-auth unsecured
  else  
    echo "    => Starting Skupper with --cluster-local option"
    skupper init --cluster-local
  fi    
fi  
