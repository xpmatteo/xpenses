#!/usr/bin/env ruby

require 'capybara'
require 'minitest/autorun'

class SmokeTest < Minitest::Test

  def setup
    system 'script/deploy.sh'
  end

  def test_summary_row
    session = Capybara::Session.new(:selenium)
    session.visit "http://test.xpenses.it.s3-website.eu-central-1.amazonaws.com/"
    p session.text
    assert session.has_content?("Expenses summary"), "not the right page?"
    table = session.find('#summary-table tbody')

    table.find('td:nth-of-type(1)').assert_text('2016-09')
    table.find('td:nth-of-type(2)').assert_text('750.53')
  end
end
