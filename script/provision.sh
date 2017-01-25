#!/bin/bash

set -e
cd "$(dirname $0)/.."

. script/lib/common.sh

[ $# = 1 ] || {
  echo "Usage: $0 <environment>"
  exit 1
}

environment=$1

terraform remote config \
    -backend=s3 \
    -backend-config="bucket=xpenses.dev.tfstate" \
    -backend-config="key=network/terraform.tfstate" \
    -backend-config="region=eu-central-1"

#
#
# if ! aws dynamodb list-tables | grep -q $env.movements; then
#   echo "Creating $env.movements"
#   aws dynamodb create-table \
#     --table-name $env.movements \
#     --attribute-definitions \
#       AttributeName=id,AttributeType=S \
#       AttributeName=date,AttributeType=S \
#     --key-schema \
#       AttributeName=id,KeyType=HASH \
#       AttributeName=date,KeyType=RANGE \
#     --provisioned-throughput \
#       ReadCapacityUnits=5,WriteCapacityUnits=5 \
#     > /dev/null
# fi
