#!/bin/bash

###
### Function : CheckDeploy 
###
function checkDeploy() {
    DEP=${1}
    NS=${2}
    EXISTS=$(kubectl get deployment ${DEP} --no-headers -n ${NS} 2> /dev/null| awk -F " " '{print $1}')
    if [ "${EXISTS}" == "${DEP}" ]; then
        echo "${DEP}"
    else
        echo ""
    fi
}
###
###
###


###
### Function : CheckAvailable
###
function checkAvailable() {
    DEP=${1}
    NS=${2}
    AVAILABLE=$(kubectl get deployment ${DEP} --no-headers -n ${NS} 2> /dev/null| awk -F " " '{print $2}')
    if [ "${AVAILABLE}" == "1/1" ]; then
        echo "OK"
    else
        echo ""
    fi
}
###
###
###


###
### Function : CheckExposedSkupper
###
function checkExposedSkupper() {
    DEP=${1}
    NS=${2}  
    EXISTS=$(skupper list-exposed -n ${NS} | grep ${DEP} | grep port | awk -F " " '{print $1}')
    if [ "${EXISTS}" == "${DEP}" ]; then
        echo "${DEP}"
    else
        echo ""
    fi
}
###
###
###


###
### Function : CheckExposedKubectl
###
function checkExposedKubectl() {
    DEP=${1}
    NS=${2}  
    EXISTS=$(kubectl get service ${DEP} --no-headers -n ${NS} | awk -F " " '{print $1}')
    if [ "${EXISTS}" == "${DEP}" ]; then
        echo "${DEP}"
    else
        echo ""
    fi
}
###
###
###


###
### Clean the house first
###
echo -e "\n\n*******************************************************"
echo -e "****  Cleaning the house "
echo -e "*******************************************************\n"
TUNPID=$(ps aux | grep "minikube tunnel" | grep -v grep | awk -F " " '{print $2}')
if [ "x${TUNPID}" != "x" ]; then 
    echo -e "\nkilling minikube tunnel with PID ${TUNPID}"; 
    kill -9 ${TUNPID}
fi

APPFWDPID=$(ps aux | grep port-forward | grep 8090 | grep -v grep | awk -F " " '{print $2}')
if [ "x${APPFWDPID}" != "x" ]; then 
    echo -e "\nkilling Port-Forward for APP/Frontend with PID ${APPFWDPID}"; 
    kill -9 ${APPFWDPID}
fi

CONFWDPID=$(ps aux | grep port-forward | grep 8092 | grep -v grep | awk -F " " '{print $2}')
if [ "x${CONFWDPID}" != "x" ]; then 
    echo -e "\nkilling Port-Forward for Console with PID ${CONFWDPID}"; 
    kill -9 ${CONFWDPID}
fi

echo -e "\nStop skupper in west"
skupper delete -n west
echo "Delete the service hello-world-frontend"
kubectl delete service/hello-world-frontend -n west
echo "Delete the deployment hello-world-frontend"
kubectl delete deployment/hello-world-frontend -n west

echo -e "\nStop skupper in east"
skupper delete -n east
echo "Delete the deployment hello-world-backend"
kubectl delete deployment/hello-world-backend -n east

echo -e "\nDelete namespace west"
kubectl delete namespace west
echo "Delete namespace east"
kubectl delete namespace east 
###
###
###


###
### Create namespaces 
###
echo -e "\n\n*******************************************************"
echo -e "****  Create the namespaces "
echo -e "*******************************************************\n"
echo "[WEST] Creating namespace west"
kubectl create namespace west

echo "[EAST] Createing namespace east"
kubectl create namespace east
###
###
###


###
### Start Skupper in West
###
echo -e "\n\n*******************************************************"
echo -e "****  Start Skupper in namespace West "
echo -e "*******************************************************\n"
export NS="west"
CMDINIT=""
MSGTUNNEL=""
MSGCONSOLE=""
#echo "[WEST] Starting minikube tunnel before starting skupper"
#nohup minikube tunnel &
#echo "Wait 10 seconds for minikube tunel"
#sleep 10

CMDINIT="skupper init --cluster-local -n ${NS}"
if [ "${1}" == "console" ] || [ "${2}" == "console" ]; then
    CMDINIT="${CMDINIT} --enable-console --console-auth unsecured"
    MSGCONSOLE="Using --enable-console --console-auth unsecured"
fi    

echo "[WEST] Check if skupper is already installed"
if [[ "$(skupper status -n ${NS})" =~ 'Skupper is not enabled' ]]; then
    echo "  => Skupper is not installed in this namespace yet"
    echo "  => Installing skupper ${MSGTUNNEL}${MSGCONSOLE}"
    ${CMDINIT}
else
    echo "  => Skupper is already installed in this namespace"
fi  
###
### 
###


###
### Start Skupper in East 
###
echo -e "\n\n*******************************************************"
echo -e "****  Start Skupper in namespace East "
echo -e "*******************************************************\n"
export NS="east"
echo "[EAST] Check if skupper is already installed"
if [[ "$(skupper status -n ${NS})" =~ 'Skupper is not enabled' ]]; then
    echo "  => Skupper is not installed in this namespace yet, installing it"
    echo "    => Starting Skupper with --cluster-local option"
    skupper init --cluster-local -n ${NS}
else
    echo "  => Skupper is already installed in this namespace"
fi  
###
### 
###


###
### Create a token for skupper 
###
echo -e "\n\n*******************************************************"
echo -e "****  Create a token for Skupper"
echo -e "*******************************************************\n"
export NS="west"
TOKENFILE=$(mktemp --tmpdir=/tmp skuppercon.XXX)
echo "[WEST] Creating a conection token and storing it at ${TOKENFILE}"
skupper token create ${TOKENFILE} -n ${NS}
if [ ${?} == 0 ]; then
    echo "  => Connection token created at ${TOKENFILE}"
else    
    echo "  => Unable to create token at ${TOKENFILE}"
    exit 1
fi

echo -e "\n\n*******************************************************"
echo -e "****  Connecting to a remote Skupper"
echo -e "*******************************************************\n"
export NS="east"
echo "[EAST] Conecting to remote skupper using the token stored at ${TOKENFILE}"
skupper link create ${TOKENFILE} -n ${NS}
if [ ${?} == 0 ]; then
    echo "  => Connection created using token from ${TOKENFILE}"
else    
    echo "  => Unable to connect using token from ${TOKENFILE}"
    exit 1
fi
###
### 
###


###
### Deploy the frontend 
###
echo -e "\n\n*******************************************************"
echo -e "****  Deploy the frontend"
echo -e "*******************************************************\n"
export NS="west"
DEPNAME="hello-world-frontend"
DEPIMAGE="quay.io/skupper/hello-world-frontend"

echo "[WEST] Checking if the deployment ${DEPNAME} already exists"
CHECKDEPLOY=$(checkDeploy ${DEPNAME} ${NS})
if [ "${CHECKDEPLOY}" == "${DEPNAME}" ]; then
    echo "  => Deployment ${DEPNAME} already exists"
else
    echo "  => Deploying it"
    kubectl create deployment ${DEPNAME} --image ${DEPIMAGE} -n ${NS}
    CHECKDEPLOY=$(checkDeploy ${DEPNAME} ${NS})
    if [ "${CHECKDEPLOY}" == "${DEPNAME}" ]; then
        echo "    => Deployment ${DEPNAME} created"
    else
        echo "    => Unable to create Deployment ${DEPNAME}. Check it manually"
        exit 1
    fi     
fi

echo "[WEST] Checking f deployment ${DEPNAME} is available"
for count in $(seq 3); do
    CHECKAVAILABLE=$(checkAvailable ${DEPNAME} ${NS})
    if [ "${CHECKAVAILABLE}" == "OK" ]; then
        echo "  => Deployment ${DEPNAME} is available"
        break 
    else
        echo "      ...Waiting 5 seconds..."
        sleep 5
    fi  
done
###
### 
###


###
### Deploy the backend 
###
echo -e "\n\n*******************************************************"
echo -e "****  Deploy the backend"
echo -e "*******************************************************\n"
export NS="east"
DEPNAME="hello-world-backend"
DEPIMAGE="quay.io/skupper/hello-world-backend"

echo "[EAST] Checking if the deployment ${DEPNAME} already exists"
CHECKDEPLOY=$(checkDeploy ${DEPNAME} ${NS})
if [ "${CHECKDEPLOY}" == "${DEPNAME}" ]; then
    echo "  => Deployment ${DEPNAME} already exists"
else
    echo "  => Deploying it"
    kubectl create deployment ${DEPNAME} --image ${DEPIMAGE} -n ${NS}
    CHECKDEPLOY=$(checkDeploy)
    if [ "${CHECKDEPLOY}" == "${DEPNAME}" ]; then
        echo "    => Deployment ${DEPNAME} created"
    else
        echo "    => Unable to create Deployment ${DEPNAME}. Check it manually"
    fi     
fi

echo "[EAST] Checking f deployment ${DEPNAME} is available"
for count in $(seq 3); do
    CHECKAVAILABLE=$(checkAvailable ${DEPNAME} ${NS})
    if [ "${CHECKAVAILABLE}" == "OK" ]; then
        echo "  => Deployment ${DEPNAME} is available"
        break 
    else
        echo "      ...Waiting 5 seconds..."
        sleep 5
    fi  
done
###
### 
###



###
### Expose the backend 
###
echo -e "\n\n*******************************************************"
echo -e "****  Expose the backend"
echo -e "*******************************************************\n"
export NS="east"
DEPNAME="hello-world-backend"
PORT="8080"
PROTO="http"

echo "[EAST] Checking if the deployment ${DEPNAME} is already exposed"
CHECKDEPLOY=$(checkExposedSkupper ${DEPNAME} ${NS})
if [ "${CHECKDEPLOY}" == "${DEPNAME}" ]; then
    echo "  => Deployment ${DEPNAME} already exposed"
else
    echo "  => Exposing it"
    skupper expose deployment ${DEPNAME} --port ${PORT} --protocol ${PROTO} -n ${NS}
    CHECKEXPOSE=$(checkExposedSkupper ${DEPNAME} ${NS})
    if [ "${CHECKEXPOSE}" == "${DEPNAME}" ]; then
        echo "    => Deployment ${DEPNAME} exposed"
    else
        echo "    => Unable to expose Deployment ${DEPNAME}. Check it manually"
    fi
fi
###
### 
###


###
### Expose the frontend
###
echo -e "\n\n*******************************************************"
echo -e "****  Expose the frontend"
echo -e "*******************************************************\n"
export NS="west"
DEPNAME="hello-world-frontend"
PORT="8080"
TYPE="LoadBalancer"

echo "[WEST] Checking if the deployment ${DEPNAME} already exposed"
CHECKDEPLOY=$(checkExposedKubectl ${DEPNAME} ${NS})
if [ "${CHECKDEPLOY}" == "${DEPNAME}" ]; then
    echo "  => Deployment ${DEPNAME} already exposed"
else
    echo "  => Exposing it"
    kubectl expose deployment ${DEPNAME} --port ${PORT} --type ${TYPE} -n ${NS}
    CHECKEXPOSE=$(checkExposedKubectl ${DEPNAME} ${NS})
    if [ "${CHECKEXPOSE}" == "${DEPNAME}" ]; then
        echo "    => Deployment ${DEPNAME} exposed"
    else
        echo "    => Unable to expose Deployment ${DEPNAME}. Check it manually"
    fi
fi
###
### 
###


###
### Create a port-forward to access the application / frontend 
###
echo -e "\n\n*******************************************************"
echo -e "****  Create a port-forward to access the frontend"
echo -e "*******************************************************\n"
export NS="west"
SERVNAME="service/hello-world-frontend"
APPPORT="8090"

kubectl port-forward --skip-headers=true ${SERVNAME} ${APPPORT}:8080 -n ${NS} &
echo "Port Forward created for Frontend"
###
### 
###


###
### Create a port-forward to access the console 
###
echo -e "\n\n*******************************************************"
echo -e "****  Create a port-forward to access the console"
echo -e "*******************************************************\n"
export NS="west"
SERVNAME="service/skupper-controller"
CONPORT="8092"

kubectl port-forward --skip-headers=true ${SERVNAME} ${CONPORT}:8080 -n ${NS} &
echo "Port Forward created for Console"
###
### 
###


###
### Final message 
###
echo -e "\nYou can interact with the test this way : "
echo "   To access the Frontend ==> curl http://0.0.0.0:${APPPORT}"

if [ "${1}" == "console" ] || [ "${2}" == "console" ]; then
    echo "   To access the Console  ==> curl http://0.0.0.0:${CONPORT}"
fi  
###
### 
###
