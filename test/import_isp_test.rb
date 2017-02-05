
require 'roo-xls'
class Account
  def load path
    @movements = Roo::Spreadsheet.open(path)

  end

  def movements year, month

    (22...26).map do |i|
      { amount: format_money(@movements.sheet('Sheet1').row(i)[3]) }
    end
  end

  private

  def format_money float
    sprintf "%.2f", float
  end
end

require 'minitest/autorun'

class ImportIspTest < Minitest::Test

  def test_import
    test_file = 'test-data/isp-movements-short.xls'

    account = Account.new
    account.load test_file

    assert_equal %w(462.73 1.50 11.50 275.00), account.movements(2016, 9).map { |m| m[:amount] }
  end

end