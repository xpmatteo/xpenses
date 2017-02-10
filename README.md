
# Install

Create a new AWS account.  Create a key pair.  Add these lines to your .bash_profile:

    export AWS_ACCESS_KEY_ID=<your access key id>
    export AWS_SECRET_ACCESS_KEY=<your secret access key>
    export XPENSES_REGION=<your preferred region>
    export XPENSES_KEY_PAIR_NAME=<name of the key pair you wish to use>
    export XPENSES_KEY_PAIR_PATH=<path to the key pair private key>

Then execute the following:

    brew install awscli         # to access AWS through the CLI
    brew install geckodriver    # for UI tests with Capybara
    brew install dynamodb-local # for unit tests

    node install -g json        # for parsing cli output in bash scripts

You will need `ruby` and `gem` installed.  Then execute

    bundle

# Environments

"Infrastructure as code" means that you should be able to create a complete new environment with a single command, and destroy it with same ease.

    script/create-environment.rb <env name>
    script/destroy-environment.rb <env name>

These will only do the part related to DynamoDB tables

    script/create-tables.rb <env name>
    script/destroy-tables.rb <env name>

You can test that the above scripts work correctly with:

    ruby -Ilib test/create_environment_test.rb

We expect to iterate on the definition of the tables.  We will experiment locally with a local DynamoDB, and this script will destroy all local tables and create them again.

    script/create-local-tables.sh

The local tables are implemented in a local dynamodb, running on port 8000.
The tables will be defined in two environments:

 * local-dev (for interactive testing)
 * local-test (for automated testing)


# Running


Locally:

    /usr/local/bin/dynamodb-local   # if you installed it with Homebrew
    script/server
    open http://localhost:4567

Remotely:

    script/deploy.sh <environment>
    open http://$(script/instance-ip <environment>)/


# Testing

RUN remote UI TESTS

    script/smoke-test.sh

RUN UNIT TESTS

A single file:

    clear; ruby -Ilib test/<name of test file>

All test files:

    rake

