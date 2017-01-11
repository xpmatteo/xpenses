#!/bin/bash

set -e
cd "$(dirname $0)/.."

. script/lib/common.sh

env='test'

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
