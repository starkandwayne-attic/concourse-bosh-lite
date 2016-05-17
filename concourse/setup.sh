#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

set -e


# To install bosh CLI & bcrypt rubygem for password encryption
bundle install

vagrant ssh -c 'sudo chown -R ubuntu ~/.bosh_config ~/tmp; [ ! -f /home/ubuntu/.ssh/id_rsa ] && ssh-keygen -N "" -f "/home/ubuntu/.ssh/id_rsa" || echo "Keys already setup" '
vagrant ssh -c 'sudo iptables -t nat -A PREROUTING -p tcp -d $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) --dport 8080 -j DNAT --to 10.244.8.2:8080'

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
_bosh -t concourse-bosh-lite upload stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent

./fetch_manifest.sh


_bosh -t concourse-bosh-lite deployment concourse.yml
_bosh -t concourse-bosh-lite -n deploy
_bosh -t concourse-bosh-lite -n delete deployment concourse -f
_bosh -t concourse-bosh-lite -n deploy

./install_fly_cli.sh
fly save-target bosh-lite --api http://$IP:8080

echo View http://${IP}:8080 to Concourse UI
