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
    movements = Roo::Spreadsheet.open(path)
    sheet = movements.sheet('Sheet1')
    for row_number in (21...100_000)
      row = sheet.row(row_number)
      date = row[0]
      amount = row[3]
      description = row[2]
      break if date.nil?
      next if amount.nil?
      month = format_month(date.year, date.month)
      movement = { month: month, amount: format_money(amount), id: rand(1_000_000_000).to_s, description: description }
      dynamodb.put_item table_name: MOVEMENTS_TABLE, item: movement
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
            ":m" => format_month(year, month)
        }
    }
    dynamodb.query(params).items
  end

  private

  def dynamodb
    @dynamodb ||= Aws::DynamoDB::Client.new
  end

  def format_month year, month
    sprintf('%04d-%02d', year, month)
  end

  def format_money float
    sprintf "%.2f", float
  end
end
