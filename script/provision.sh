#!/bin/bash

set -e
cd "$(dirname $0)/.."

env='test'
bucket="$env.xpenses.it"

aws s3api put-bucket-policy --bucket $bucket --policy file://config/hosting-bucket-policy.json

ec2_instance_ip=$(aws ec2 describe-instances --filter Name=tag:Name,Values=$env.xpenses | grep 'PublicIpAddress' | awk '{print $2}')
cat /dev/null > /tmp/empty-file
aws s3 cp /tmp/empty-file s3://$bucket/api --website-redirect http://$ec2_instance_ip/api

if ! aws dynamodb list-tables | grep -q $env.movements; then
  aws dynamodb create-table \
    --table-name $env.movements \
    --attribute-definitions \
      AttributeName=id,AttributeType=S \
      AttributeName=date,AttributeType=S \
    --key-schema \
      AttributeName=id,KeyType=HASH \
      AttributeName=date,KeyType=RANGE \
    --provisioned-throughput \
      ReadCapacityUnits=5,WriteCapacityUnits=5 \
    > /dev/null
fi
