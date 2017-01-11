#!/bin/bash

set -e
cd "$(dirname)/.."

aws s3 cp web/index.html s3://test.xpenses.it/
