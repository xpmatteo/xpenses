#!/bin/bash

set -e
cd "$(dirname $0)/.."

DYNAMODB_ENDPOINT=http://localhost:8000 script/destroy-tables.rb local-dev
DYNAMODB_ENDPOINT=http://localhost:8000 script/destroy-tables.rb local-test

