ENV['RACK_ENV'] = 'test'
ENV['XPENSES_ENV'] = 'local-test'
ENV['DYNAMODB_ENDPOINT'] = 'http://localhost:8000/'

require 'api'
require 'minitest/autorun'
require 'rack/test'


class ImportIspIntegrationTest < Minitest::Test

  TEST_FILE = 'test-data/isp-movements-short.xls'

  def setup
    Account.new.clear
    @session = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
  end

  def test_summary_row_empty
    assert_equal "[]", @session.get('/api/summary').body
  end

  def test_summary_row_september
    Account.new.load TEST_FILE
    assert_equal '[{"month": "2016-09", "total": "750.53"}]', @session.get('/api/summary').body
  end

  def test_upload
    @session.post "/api/movements", "file" => Rack::Test::UploadedFile.new(TEST_FILE, "application/xcel")
    assert @session.last_response.ok?, "last response #{@session.last_response.status}"
  end

  def test_movements
    @session.post "/api/movements", "file" => Rack::Test::UploadedFile.new(TEST_FILE, "application/xcel")
    assert_equal '[...]', @session.get('/api/movements').body
  end

end
