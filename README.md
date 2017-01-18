
INSTALL

    brew install jq             # for parsing CLI output
    brew install geckodriver    # for UI tests with Capybara
    brew install dynamodb-local # for unit tests

RUN remotely:

    open http://35.157.46.92

RUN locally:

    ruby lib/api.rb
    open http://localhost:4567

RUN UI TESTS

    script/smoke-test.sh



RUN UNIT TESTS

    ?