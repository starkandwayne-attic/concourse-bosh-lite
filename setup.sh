#!/bin/bash

vagrant up --provider=aws
vagrant ssh -c 'sudo iptables -t nat -A PREROUTING -p tcp -d $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) --dport 8080 -j DNAT --to 10.244.8.2:8080'

IP=$(vagrant ssh-config | grep HostName | awk '{print $2}')
yes admin | bosh target $IP

bosh upload release https://bosh.io/d/github.com/concourse/concourse
bosh upload release https://bosh.io/d/github.com/cloudfoundry-incubator/garden-linux-release
bosh upload stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent

bosh deployment concourse.yml
bosh -n deploy
bosh -n delete deployment concourse -f
bosh -n deploy

echo export ATC_URL=http://${IP}:8080

./add-route.sh
