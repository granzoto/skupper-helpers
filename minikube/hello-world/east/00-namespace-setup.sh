#!/bin/bash

echo "[] Check if config-east exists"
if [ ! -f ~/.kube/config-east ]; then
  echo "  => Copying config as config-east"
  cp -f ~/.kube/config ~/.kube/config-east
fi  

if [ "${NS}" != "east" ]; then
  echo "[] Please set the NS variable : "
  echo "  => export NS=\"east\""
else
  echo "NS variable is properly set"  
fi


if [ "${KUBECONFIG}" != ~/.kube/config-east ]; then
  echo "[] Please set the KUBECONFIG variable : "
  echo "   => export KUBECONFIG=~/.kube/config-east"
  echo ""
  echo "After that, rerun this script to continue"
  exit 1
else
  echo "KUBECONFIG variable is properly set"  
fi

echo "[] Createing namespace east"
kubectl create namespace east


echo "[] Setting context to east"
kubectl config set-context --current --namespace east

echo "All set for east namespace"
