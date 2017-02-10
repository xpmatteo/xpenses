ENV['RACK_ENV'] = 'test'
ENV['XPENSES_ENV'] = 'local-test'

require 'api'
require 'minitest/autorun'
require 'capybara'

class ImportIspWebTest < Minitest::Test

  def setup
  end

  def teardown
  end

  # See here for Capybara docs
  # http://www.rubydoc.info/github/jnicklas/capybara/master/Capybara/Session

  def test_summary_row
    session = Capybara::Session.new(:rack_test, Sinatra::Application.new)

    session.visit "/"
    session.attach_file("Upload a file", 'test-data/isp-movements-short.xls')

    session.visit "/"
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
