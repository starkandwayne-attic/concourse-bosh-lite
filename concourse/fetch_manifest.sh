#!/bin/bash

if [[ ! -f concourse.yml ]]; then
  curl -L -o concourse.yml https://raw.githubusercontent.com/concourse/concourse/develop/manifests/bosh-lite.yml
fi
