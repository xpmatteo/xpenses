
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

  def clear
    result = dynamodb.scan(table_name: MOVEMENTS_TABLE)
    result.items.each do |item|
      dynamodb.delete_item({
          table_name: MOVEMENTS_TABLE,
          key: {
              month: item["month"],
              id: item['id'],
          },
      })
    end
  end

  def load path
    @movements = Roo::Spreadsheet.open(path)

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
    params = {
        table_name: MOVEMENTS_TABLE,
        key_condition_expression: "#month = :m",
        expression_attribute_names: {
            "#month" => "month"
        },
        expression_attribute_values: {
            ":m" => sprintf('%04d-%02d', year, month)
        }
    }
    dynamodb.query(params).items
  end

  private

  def dynamodb
    @dynamodb ||= Aws::DynamoDB::Client.new
  end

  def format_money float
    sprintf "%.2f", float
  end
end

require 'minitest/autorun'

class ImportIspTest < Minitest::Test

  def test_import
    test_file = 'test-data/isp-movements-short.xls'

    account = Account.new
    account.clear
    account.load test_file

    assert_equal %w(462.73 1.50 11.50 275.00).sort, account.movements(2016, 9).map { |m| m['amount'] } .sort
  end

end
