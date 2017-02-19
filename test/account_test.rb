require 'minitest/autorun'

ENV['XPENSES_REGION'] = 'eu-central-1'
ENV['XPENSES_ENV'] = 'local-test'
ENV['DYNAMODB_ENDPOINT'] = 'http://localhost:8000/'

require 'account'

class AccountTest < Minitest::Test
  TEST_FILE = 'test-data/isp-movements-short.xls'

  def setup
    @account = Account.new
    @account.clear
    @account.load TEST_FILE
  end

  def test_movements_month
    january = @account.movements_month(2017, 1)
    assert_equal ["10.00", "250.00", "6.40"].sort, january.map{ |m| m['amount'] }.sort
    february = @account.movements_month(2017, 2)
    assert_equal ["95.51"], february.map{ |m| m['amount'] }
  end

  def test_movements
    assert_equal ["10.00", "250.00", "6.40", "95.51"].sort, @account.movements.map{ |m| m['amount'] }.sort
  end

  def test_summary
    expected = [
      {month: '2017-01', total: '266.40'},
      {month: '2017-02', total: '95.51'},
    ]
    assert_equal expected, @account.summary
  end

  def test_no_movements
    assert_equal [], @account.movements_month(2016, 8)
    assert_equal [], @account.movements_month(2016, 11)
  end

  def test_skip_duplicate_lines
    @account.load TEST_FILE # again!
    @account.load TEST_FILE # and again!

    assert_equal ["10.00", "250.00", "6.40", "95.51"].sort, @account.movements.map{ |m| m['amount'] }.sort
  end

end
