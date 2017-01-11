#!/usr/bin/env ruby

require 'capybara'
require 'minitest/autorun'

class SmokeTest < Minitest::Test

  def setup
    $env = 'test'
    ENV['XPENSES_ENV'] = $env
    sh "aws dynamodb delete-table --table-name #$env.movements > /dev/null"
    sh 'script/deploy.sh'
    sh 'script/upload.sh test-data/isp-movements-short.xls'
  end

  # See here for Capybara docs
  # http://www.rubydoc.info/github/jnicklas/capybara/master/Capybara/Session

  def test_summary_row
    session = Capybara::Session.new(:selenium)
    session.visit "http://#$env.xpenses.it.s3-website.eu-central-1.amazonaws.com/"
    p session.text
    assert session.has_content?("Expenses summary"), "not the right page?"
    table = session.find('#summary-table tbody')

    table.find('td:nth-of-type(1)').assert_text('2016-09')
    table.find('td:nth-of-type(2)').assert_text('750.53')
  end

  private

  def sh command
    assert system(command), "Failed execution of '#{command}'"
  end
end