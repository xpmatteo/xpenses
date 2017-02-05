
require 'minitest/autorun'

class ImportIspTest < Minitest::Test

  def test_import
    test_file = 'test-data/isp-movements-short.xls'

    account = Account.new
    account.load test_file

    assert_equal %w(462.73 1.50 11.50 275.00), account.month(2016, 9).map(&:amount)
  end

end