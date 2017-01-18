#!/bin/bash

terraform remote config -backend=s3 \
  -backend-config="bucket=mv-free-terraform-experiment-state" \
  -backend-config="key=network/terraform.tfstate" \
  -backend-config="region=eu-central-1"
