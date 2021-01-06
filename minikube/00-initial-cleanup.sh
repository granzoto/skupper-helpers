#!/bin/bash

echo "Removing all configs from .kube"
if [ -d "~/.kube" ]; then
  rm -f ~/.kube/config*
fi  

echo "Setup your cluster provider now"
