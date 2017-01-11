#!/bin/bash

set -e
cd "$(dirname $0)/.."

env='test'
bucket="$env.xpenses.it"

aws s3 cp web/index.html s3://$bucket/

