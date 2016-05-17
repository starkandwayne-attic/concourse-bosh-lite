#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR

set -e


# To install bosh CLI & bcrypt rubygem for password encryption
bundle install

vagrant ssh -c 'sudo chown -R ubuntu ~/.bosh_config ~/tmp; [ ! -f /home/ubuntu/.ssh/id_rsa ] && ssh-keygen -N "" -f "/home/ubuntu/.ssh/id_rsa" || echo "Keys already setup" '
vagrant ssh -c 'sudo iptables -t nat -A PREROUTING -p tcp -d $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) --dport 8080 -j DNAT --to 10.244.8.2:8080'
vagrant ssh -c 'sudo iptables -t nat -D PREROUTING -p tcp -d $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) --dport 443 -j DNAT --to 10.244.0.34:443'
vagrant ssh -c 'sudo iptables -t nat -A PREROUTING -p tcp -d $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) --dport 443 -j DNAT --to 10.244.8.3:443'
vagrant ssh -c 'sudo iptables -t nat -D PREROUTING -p tcp -d $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) --dport 80 -j DNAT --to 10.244.0.34:80'
vagrant ssh -c 'sudo iptables -t nat -A PREROUTING -p tcp -d $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) --dport 80 -j DNAT --to 10.244.8.3:80'

./update.sh
