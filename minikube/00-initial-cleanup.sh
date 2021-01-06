#!/bin/bash

echo "[] Removing all configs from .kube"
if [ -d ~/.kube ]; then
  echo "  => Removing old config files from ~/.kube/"
  rm -f ~/.kube/config*
fi  

echo "Setup your cluster provider now"
