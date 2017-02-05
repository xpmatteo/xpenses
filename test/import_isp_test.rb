require 'minitest/autorun'

ENV['XPENSES_ENV'] = 'local-test'
ENV['DYNAMODB_ENDPOINT'] = 'http://localhost:8000/'

require 'account'

class ImportIspTest < Minitest::Test

  def setup
    test_file = 'test-data/isp-movements-short.xls'
    @account = Account.new
    @account.clear
    @account.load test_file
  end

  def test_september
    september = @account.movements(2016, 9)
    assert_equal %w(462.73 1.50 11.50 275.00).sort, september.map{ |m| m['amount'] }.sort
  end

  def test_no_movements
    assert_equal [], @account.movements(2016, 8)
    assert_equal [], @account.movements(2016, 10)
  end
end
