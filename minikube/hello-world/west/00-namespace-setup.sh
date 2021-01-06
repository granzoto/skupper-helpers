#!/bin/bash

echo "[] Check if config-west exists"
if [ ! -f ~/.kube/config-west ]; then
  echo "  => Copying config as config-west"
  cp -f ~/.kube/config ~/.kube/config-west
fi  

if [ "${NS}" != "west" ]; then
  echo "[] Please set the NS variable : "
  echo "  => export NS=\"west\""
else
  echo "NS variable is properly set"  
fi


if [ "${KUBECONFIG}" != ~/.kube/config-west ]; then
  echo "[] Please set the KUBECONFIG variable aa${KUBECONFIG}aa: "
  echo "   => export KUBECONFIG=~/.kube/config-west"
  echo ""
  echo "After that, rerun this script to continue"
  exit 1
else
  echo "KUBECONFIG variable is properly set"  
fi

echo "[] Createing namespace west"
kubectl create namespace west


echo "[] Setting context to west"
kubectl config set-context --current --namespace west

echo "All set for west namespace"
