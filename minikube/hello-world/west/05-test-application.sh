#!/bin/bash

echo "Trying to connect to the frontend"
curl $(kubectl get service hello-world-frontend -o jsonpath='http://{.status.loadBalancer.ingress[0].ip}:8080/')

