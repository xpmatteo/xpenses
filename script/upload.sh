#!/bin/bash

cd "$(dirname $0)/.."
set -e

if [ $# -lt 1 ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

curl \
  -F "movements=@$1" \
  "http://35.157.46.92/api/movements"
