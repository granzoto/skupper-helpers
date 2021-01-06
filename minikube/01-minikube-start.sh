#!/bin/bash

echo "[] Checking if minikube is running"
minikube status 2>&1> /dev/null
if [ ${?} -ne 0 ]; then
  echo "  => Minikube is not running, starting it"
  minikube start
  sleep 3
  minikube status 2>&1> /dev/null
  if [ ${?} -ne 0 ]; then
    echo "    => Minikube startup failed, run it manually"
  else
    echo "    => Minikube is now started"
  fi
else    
  echo "  => Minikube is already running"
fi  

