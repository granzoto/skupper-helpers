#!/bin/bash

echo "[] Deleting Skupper"
skupper delete

echo "[] Deleting deployment hello-world-backend"
kubectl delete deployment/hello-world-backend

echo "[] Stop Minikube tunnel, if running"
TUNPID=$(ps aux | grep "minikube tunnel" | grep -v "grep" | awk -F " " '{print $2}')
if [ "x${TUNPID}" != "x" ]; then
    echo "  => Killing minikube tunnel"
    kill -9 ${TUNPID}
fi

echo "[] All removed from East"
