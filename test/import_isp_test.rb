
ENV['XPENSES_ENV'] = 'local-test'
ENV['DYNAMODB_ENDPOINT'] = 'http://localhost:8000/'


require 'roo-xls'
require "aws-sdk-core"

class Account

  XPENSES_ENV = ENV['XPENSES_ENV'] or raise "Please set env var XPENSES_ENV"
  MOVEMENTS_TABLE = "xpenses-movements-#{XPENSES_ENV}"
  if ENV['DYNAMODB_ENDPOINT']
    Aws.config.update({ endpoint: ENV['DYNAMODB_ENDPOINT'] })
  end

  def load path
    @movements = Roo::Spreadsheet.open(path)
    dynamodb = Aws::DynamoDB::Client.new

    (21...26).each do |row|
      date = @movements.sheet('Sheet1').row(row)[2]
      amount = @movements.sheet('Sheet1').row(row)[3]
      next unless amount
      movement = { month: '2016-09', amount: format_money(amount), id: rand(1_000_000_000).to_s }
    	params = {
        table_name: MOVEMENTS_TABLE,
    		item: movement,
     	}
    	dynamodb.put_item(params)
    end
  end

  def movements year, month
    # result = []
    # (21...26).each do |row|
    #   amount = @movements.sheet('Sheet1').row(row)[3]
    #   result << { amount: format_money(amount) } if amount
    # end
    # result

    dynamodb = Aws::DynamoDB::Client.new
    params = {
        table_name: MOVEMENTS_TABLE,
        key_condition_expression: "#month = :m",
        expression_attribute_names: {
            "#month" => "month"
        },
        expression_attribute_values: {
            ":m" => '2016-09'
        }
    }

    dynamodb.query(params).items
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

    p account.movements(2016, 9)

    assert_equal %w(462.73 1.50 11.50 275.00), account.movements(2016, 9).map { |m| m['amount'] }
  end

end
