#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

username=$1; shift
password=$1; shift

if [[ "${password}X" == "X" ]]; then
  echo "USAGE: ./encrypt_concourse.sh <username> <password>"
  exit 1
fi

encrypted_password=$(ruby encrypt_password.rb "${password}")

cat <<EOF
    properties:
      tsa:
        atc:
          username: ${username}
          password: ${password}
    
      atc:
        basic_auth_username: ${username}
        basic_auth_encrypted_password: ${encrypted_password}
        development_mode: false
        publicly_viewable: true
EOF
