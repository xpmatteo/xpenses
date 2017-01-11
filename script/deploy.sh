#!/bin/bash

set -e
cd "$(dirname $0)/.."

bucket='test.xpenses.it'

aws s3api put-bucket-policy --bucket $bucket --policy file://config/hosting-bucket-policy.json
aws s3 cp web/index.html s3://$bucket/
