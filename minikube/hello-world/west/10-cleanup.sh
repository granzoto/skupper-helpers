#!/bin/bash

echo "[] Deleting Skupper"
skupper delete

echo "[] Deleting service hello-world-frontend"
kubectl delete service/hello-world-frontend

echo "[] Deleting deployment hello-world-frontend"
kubectl delete deployment/hello-world-frontend

echo "[] Stop Minikube tunnel, if running"
TUNPID=$(ps aux | grep "minikube tunnel" | grep -v "grep" | awk -F " " '{print $2}')
if [ "x${TUNPID}" != "x" ]; then
    echo "  => Killing minikube tunnel"
    kill -9 ${TUNPID}
fi

echo "[] All removed from West"
