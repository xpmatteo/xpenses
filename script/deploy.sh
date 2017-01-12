#!/bin/bash

set -e
cd "$(dirname $0)/.."

. script/lib/common.sh

env='test'

ip=$(ec2_instance_ip)

ssh -i $private_key ec2-user@$ip <<EOF
mkdir -p xpenses/log || true
EOF

scp -i $private_key -r lib public ec2-user@$ip:xpenses

ssh -i $private_key ec2-user@$ip <<EOF
set -e

sudo yum update -y
sudo yum install gcc glibc-devel glibc-headers ruby-devel -y

sudo gem install sinatra json aws-sdk-core --no-ri --no-rdoc

echo "About to run"
sudo killall ruby || true
sleep 2
cd xpenses
sudo nohup ruby lib/api.rb -p 80 -o 0.0.0.0 >> log/$env.out 2>&1 &
tail -f log/$env.out
EOF
