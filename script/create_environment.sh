#!/bin/bash

set -e
cd "$(dirname $0)/.."

. script/lib/common.sh

[ $# = 1 ] || {
  echo "Usage: $0 <environment>"
  exit 1
}

environment=$1

terraform apply -var environment=$environment provision


