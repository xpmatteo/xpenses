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

  def test_summary
    @session.post "/api/movements", "file" => Rack::Test::UploadedFile.new(TEST_FILE, "application/octet-stream")
    assert_equal 302, @session.last_response.status

    expected = '[{"month":"2017-01","total":"266.40"},{"month":"2017-02","total":"95.51"}]'
    assert_equal expected, @session.get('/api/summary').body
  end

  def test_movements
    skip
    @session.post "/api/movements", "file" => Rack::Test::UploadedFile.new(TEST_FILE, "application/xcel")
    assert_equal '[...]', @session.get('/api/movements').body
  end

end
