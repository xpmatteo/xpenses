#!/bin/bash

set -e
cd "$(dirname $0)/.."

. script/lib/common.sh

env='test'
bucket="$env.xpenses.it"


aws s3 cp web/index.html s3://$bucket/

ip=$(ec2_instance_ip)
scp -i $private_key lib/api.rb ec2-user@$ip:
ssh -i $private_key ec2-user@$ip <<EOF
set -e

sudo yum update -y
sudo yum install gcc glibc-devel glibc-headers -y
sudo yum install ruby-devel -y

sudo gem install sinatra json --no-ri --no-rdoc

echo "About to run"
sudo killall ruby || true
sleep 1
sudo nohup ruby api.rb -p 80 -o 0.0.0.0 \&
sleep 1
echo "About to quit"
EOF
