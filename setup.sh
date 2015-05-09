#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

set -e

# To install bosh CLI & bcrypt rubygem for password encryption
bundle install

vagrant up --provider=aws
vagrant ssh -c 'sudo chown -R ubuntu ~/.bosh_config ~/tmp; ssh-keygen -N "" -f "/home/ubuntu/.ssh/id_rsa" '
vagrant ssh -c 'sudo iptables -t nat -A PREROUTING -p tcp -d $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) --dport 8080 -j DNAT --to 10.244.8.2:8080'

IP=$(vagrant ssh-config | grep HostName | awk '{print $2}')
yes admin | bosh target $IP concourse-bosh-lite
bosh target $IP concourse-bosh-lite

bosh -t concourse-bosh-lite upload release https://bosh.io/d/github.com/concourse/concourse
bosh -t concourse-bosh-lite upload release https://bosh.io/d/github.com/cloudfoundry-incubator/garden-linux-release
bosh -t concourse-bosh-lite upload stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent

./fetch_manifest.sh


bosh -t concourse-bosh-lite deployment concourse.yml
bosh -t concourse-bosh-lite -n deploy
bosh -t concourse-bosh-lite -n delete deployment concourse -f
bosh -t concourse-bosh-lite -n deploy

./install_fly_cli.sh
fly save-target bosh-lite --api http://$IP:8080

echo View http://${IP}:8080 to Concourse UI
