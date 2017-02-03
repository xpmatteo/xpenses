
INSTALL

Create a new AWS account.  Create a key pair.  Add these lines to your .bash_profile:

    export AWS_ACCESS_KEY_ID=<your access key id>
    export AWS_SECRET_ACCESS_KEY=<your secret access key>
    export AWS_DEFAULT_REGION=<your preferred region>
    export XPENSES_KEY_PAIR_NAME=<name of the key pair you wish to use>
    export XPENSES_KEY_PAIR_PATH=<path to the key pair private key>

Then execute the following:

    brew install awscli         # to access AWS through the CLI
    brew install geckodriver    # for UI tests with Capybara
    brew install dynamodb-local # for unit tests

    node install -g json        # for parsing cli output in bash scripts

You will need `ruby` and `gem` installed.  Then execute

    bundle

MANIPULATE ENVIRONMENTS

    script/create-environment.rb <env name>
    script/destroy-environment.rb <env name>
    script/create-tables.rb <env name>
    script/destroy-tables.rb <env name>

TEST CREATION AND DESTRUCTION OF ENVS

    ruby -Ilib test/create_environment_test.rb

RUN locally:

    script/create-local-tables.sh

This will (re-)create the local tables.
The local tables are implemented in a local dynamodb, running on port 8000.
The tables will be defined in two environments:

 * local-dev (for interactive testing)
 * local-test (for automated testing)

Then

    /usr/local/bin/dynamodb-local
    script/server
    open http://localhost:4567

RUN remotely:

    script/deploy.sh <environment>
    open http://$(script/instance-ip <environment>)/

RUN remote UI TESTS

    script/smoke-test.sh

RUN UNIT TESTS

    TBD