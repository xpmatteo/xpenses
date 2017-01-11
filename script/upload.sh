#!/bin/bash

cd "$(dirname $0)/.."
set -e

if [ $# -lt 1 ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

curl \
  -F "movements=@$1" \
  "http://$XPENSES_ENV.xpenses.it.s3-website.eu-central-1.amazonaws.com/api/movements"