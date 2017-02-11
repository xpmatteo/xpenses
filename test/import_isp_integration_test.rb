ENV['RACK_ENV'] = 'test'
ENV['XPENSES_ENV'] = 'local-test'
ENV['DYNAMODB_ENDPOINT'] = 'http://localhost:8000/'

require 'api'
require 'minitest/autorun'
require 'rack/test'


class ImportIspIntegrationTest < Minitest::Test

  def setup
    @session = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
  end

  def teardown
  end

  def test_summary_row_empty
    @session.get '/api/summary'
    # table = session.find('#summary-table tbody')
    # table.find('td:nth-of-type(1)').assert_text('2016-09')
    # table.find('td:nth-of-type(2)').assert_text('750.53')
  end

  def xtest_upload
    test_file = 'test-data/isp-movements-short.xls'
    @session.post "/api/movements", "file" => Rack::Test::UploadedFile.new(test_file, "application/xcel")
    assert @session.last_response.ok?, "last response #{@session.last_response.status}"
  end
end
