#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

#         $os_name $os_hardware
# OS X -  Darwin   x86_64
# Linux - Linux    x86_64
os_name=$(uname -s)
os_hardware=$(uname -m)

bin_dir=$1; shift
source_line=

if [ "$bin_dir" == "" ]; then
  if [[ $EUID -ne 0 ]]; then
    if [[ -d $HOME/bin ]]; then
      bin_dir="$HOME/bin"
    else
      bin_dir="$DIR/bin"
      source_line="export PATH=\$PATH:$DIR/bin"
    fi
  else
    bin_dir="/usr/bin"
  fi
fi

[ "$bin_dir" == "" ] && display_error "No destination specified!"
[ -d $bin_dir ] || mkdir -p $bin_dir > /dev/null 2>&1 || display_error "Failed to create $bin_dir"
[ -z `which curl` ] && display_error "Could not find curl
  linux: apt-get install curl
  mac:   brew install curl
"

IP=$(vagrant ssh-config | grep HostName | awk '{print $2}')
CONCOURSE_HOST=${CONCOURSE_HOST:-$IP:8080}

if [[ "${os_hardware}" != "x86_64" ]]; then
  echo "The 'fly' CLI is only pre-built for 64-bit platforms"
  exit 1
fi
if [[ "${os_name}" == "Darwin" ]]; then
  download_url="http://$CONCOURSE_HOST/api/v1/cli?arch=amd64&platform=darwin"
elif [[ "${os_name}" == "Linux" ]]; then
  download_url="http://$CONCOURSE_HOST/api/v1/cli?arch=amd64&platform=linux"
else
  echo "This installer script only support OS X and Linux"
  exit 1
fi

download_file=${bin_dir}/fly

echo "Downloading ${download_url}..."
curl -k -L -H "Accept: application/octet-stream" $download_url -o ${download_file}

chmod +x ${download_file}

if [[ "${source_line}X" != "X" ]]; then
  echo "Add the following to your profile; or run locally to add 'fly' to your \$PATH"
  echo "${source_line}"
fi
