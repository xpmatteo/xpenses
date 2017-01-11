#!/bin/bash

set -e
cd "$(dirname $0)/.."

. script/lib/common.sh

env='test'
bucket="$env.xpenses.it"

aws s3api put-bucket-policy --bucket $bucket --policy file://config/hosting-bucket-policy.json

ip=$(ec2_instance_ip)
cat /dev/null > /tmp/empty-file
aws s3 cp /tmp/empty-file s3://$bucket/api --website-redirect http://$ip/api

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
