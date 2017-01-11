#!/bin/bash

set -e
cd "$(dirname $0)/.."

env='test'

bucket="$env.xpenses.it"

aws s3api put-bucket-policy --bucket $bucket --policy file://config/hosting-bucket-policy.json

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

aws s3 cp web/index.html s3://$bucket/

