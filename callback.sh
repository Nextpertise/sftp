#!/bin/bash

p_user=${1}
shift
p_filename=$(printf "$*")

rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  REPLY="${encoded}"
}

# Apply URL encode
rawurlencode "$p_filename"
p_filename=${REPLY}
t_string=$(cat /var/run/sftp/users.conf | grep "${p_user}:" | awk -F ':' '{print $6":"$7}')
if [ -z "${t_string}" ]; then
    # No callback found
    exit 0
fi
url=$(echo ${t_string} | sed -e "s/{filename}/${p_filename}/" | sed -e "s/{user}/${p_user}/")

curl -s --output /dev/null -A "sFTP-Server/Callback (1.1)" ${url} > /dev/null
