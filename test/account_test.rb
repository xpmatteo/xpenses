require 'minitest/autorun'

ENV['XPENSES_REGION'] = 'eu-central-1'
ENV['XPENSES_ENV'] = 'local-test'
ENV['DYNAMODB_ENDPOINT'] = 'http://localhost:8000/'

require 'account'

class AccountTest < Minitest::Test

  def setup
    test_file = 'test-data/isp-movements-short.xls'
    @account = Account.new
    @account.clear
    @account.load test_file
  end

  def test_movements
    september = @account.movements(2016, 9)
    assert_equal %w(462.73 1.50 11.50 275.00).sort, september.map{ |m| m['amount'] }.sort
  end

  def test_summary
    assert_equal [{month: '2016-09', total: '750.73'}], @account.summary
  end

  def test_no_movements
    assert_equal [], @account.movements(2016, 8)
    assert_equal [], @account.movements(2016, 10)
  end
end
