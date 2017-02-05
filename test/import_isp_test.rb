
require 'roo-xls'
require "aws-sdk-core"

class Account
  def load path
    @movements = Roo::Spreadsheet.open(path)
    @env=ENV['XPENSES_ENV'] or raise "Please set env var XPENSES_ENV"
    if ENV['DYNAMODB_ENDPOINT']
      Aws.config.update({ endpoint: ENV['DYNAMODB_ENDPOINT'] })
    end

    movements_table = "xpenses-movements-#{@env}"
    dynamodb = Aws::DynamoDB::Client.new

    (21...26).each do |row|
      date = @movements.sheet('Sheet1').row(row)[2]
      amount = @movements.sheet('Sheet1').row(row)[3]
      next unless amount
      movement = { date: date.to_s, amount: format_money(amount), id: rand(1_000_000_000).to_s }
    	params = {
        table_name: movements_table,
    		item: movement,
     	}
    	result = dynamodb.put_item(params)
    end

  end

  def movements year, month
    result = []
    (21...26).each do |row|
      amount = @movements.sheet('Sheet1').row(row)[3]
      result << { amount: format_money(amount) } if amount
    end
    result
  end

  private

  def format_money float
    sprintf "%.2f", float
  end
end

require 'minitest/autorun'

class ImportIspTest < Minitest::Test

  def test_import
    ENV['XPENSES_ENV'] = 'local-test'
    ENV['DYNAMODB_ENDPOINT'] = 'http://localhost:8000/'
    test_file = 'test-data/isp-movements-short.xls'

    account = Account.new
    account.load test_file

    assert_equal %w(462.73 1.50 11.50 275.00), account.movements(2016, 9).map { |m| m[:amount] }
  end

end
