require 'roo-xls'
require "aws-sdk-core"

def getenv variable_name
  ENV[variable_name] or raise "Please set environment variable '#{variable_name}'"
end
Aws.config.update({ region: getenv('XPENSES_REGION') })
if ENV['DYNAMODB_ENDPOINT']
  Aws.config.update({ endpoint: ENV['DYNAMODB_ENDPOINT'] })
end
if getenv('XPENSES_ENV').start_with?('local')
  if !ENV['DYNAMODB_ENDPOINT']
    raise "Local environment #{getenv('XPENSES_ENV')} needs env variable DYNAMODB_ENDPOINT"
  end
  if !system "curl -s #{ENV['DYNAMODB_ENDPOINT']} -o /dev/null"
    raise "It seems local DynamoDB is not started"
  end
end

class Account

  XPENSES_ENV = getenv('XPENSES_ENV')
  MOVEMENTS_TABLE = "xpenses-movements-#{XPENSES_ENV}"

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
