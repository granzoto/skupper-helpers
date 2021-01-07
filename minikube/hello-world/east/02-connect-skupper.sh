#!/bin/bash

function usage() {
  echo "Usage: "
  echo "  ${0} [option] [filename]"
  echo "    option   : create or connect"
  echo "    filename : where to store the token, or where to read from (yaml format)"
  exit 1
}

if [ $# -lt 2 ]; then
  usage
fi  

if [ "${1}" != "create" ] && [ "${1}" != "connect" ]; then
  usage
fi
    
if [ "${1}" == "create" ]; then
  echo "[] Creating a conection token and storing it at ${2}"
  skupper connection-token ${2}
  if [ ${?} == 0 ]; then
    echo "  => Connection token created at ${2}"
  else    
    echo "  => Unable to create token at ${2}"
  fi
else    
  echo "[] Conecting to remote skupper using the token stored at ${2}"
  skupper connect ${2}
  if [ ${?} == 0 ]; then
    echo "  => Connection created using token from ${2}"
  else    
    echo "  => Unable to connect using token from ${2}"
  fi
fi    

