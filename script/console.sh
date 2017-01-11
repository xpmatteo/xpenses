#!/bin/bash

env=test

. script/lib/common.sh

ip=$(ec2_instance_ip)
echo $ip
exec ssh ec2-user@$ip -i $private_key