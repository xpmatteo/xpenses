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
    -backend-config="bucket=xpenses.tfstate" \
    -backend-config="key=network/$environment/terraform.tfstate" \
    -backend-config="region=eu-central-1"

terraform apply -var environment=$environment provision


