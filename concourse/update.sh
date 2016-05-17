#!/bin/bash

IP=$(vagrant ssh-config | grep HostName | awk '{print $2}')

_bosh() {
  bundle exec bosh $@
}

yes admin | _bosh target $IP concourse-bosh-lite
_bosh target $IP concourse-bosh-lite

if [[ "$(which jq)X" == "X" ]]; then
  echo "WARNING: jq not installed - cannot detect matching release versions"
  echo "WARNING: uploading latest concourse/garden-linux; which might not work together"
  _bosh -t concourse-bosh-lite upload release https://bosh.io/d/github.com/concourse/concourse
  _bosh -t concourse-bosh-lite upload release https://bosh.io/d/github.com/cloudfoundry-incubator/garden-linux-release
else
  curl -s https://api.github.com/repos/concourse/concourse/releases/latest | jq -r ".assets[].browser_download_url" | grep tgz | xargs -L1 bundle exec bosh -t concourse-bosh-lite upload release
fi
_bosh upload release https://bosh.io/d/github.com/cloudfoundry-community/cf-haproxy-boshrelease
set +e
_bosh upload stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent --skip-if-exists
set -e

./fetch_manifest.sh


_bosh -t concourse-bosh-lite deployment concourse.yml
_bosh -t concourse-bosh-lite -n deploy
_bosh -t concourse-bosh-lite -n delete deployment concourse -f
_bosh -t concourse-bosh-lite -n deploy

./install_fly_cli.sh
fly -t tutorial login --concourse-url http://$IP

echo View http://${IP} to Concourse UI
