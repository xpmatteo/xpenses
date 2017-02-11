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

  def test_movements_month
    september = @account.movements_month(2016, 9)
    assert_equal %w(462.73 1.50 11.50 275.00).sort, september.map{ |m| m['amount'] }.sort
  end

  def test_movements
    movements = @account.movements
    assert_equal %w(462.73 1.50 11.50 275.00 123.45).sort, movements.map{ |m| m['amount'] }.sort
  end

  def test_summary
    expected = [
      {month: '2016-09', total: '750.73'},
      {month: '2016-10', total: '123.45'},
    ]
    assert_equal expected, @account.summary
  end

  def test_no_movements
    assert_equal [], @account.movements_month(2016, 8)
    assert_equal [], @account.movements_month(2016, 11)
  end
end
