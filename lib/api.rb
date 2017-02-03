require 'sinatra'
require 'json'
require "aws-sdk-core"

Aws.config.update({ region: 'eu-central-1' })
if ENV['DYNAMODB_ENDPOINT']
  Aws.config.update({ endpoint: ENV['DYNAMODB_ENDPOINT'] })
end
@env=ENV['XPENSES_ENV'] or raise "Please set env var XPENSES_ENV"
movements_table = "xpenses-movements-#{@env}"

get '/' do
  send_file 'public/index.html', type: :html
end

get '/js/jquery' do
  send_file 'public/js/jquery-1.10.2.js', type: 'application/javascript'
end


get '/api/summary' do
  content_type :json

  dynamodb = Aws::DynamoDB::Client.new
  september = { month: '2016-09', total: 0}
  params = {
    table_name: movements_table,
  }
  movements = dynamodb.scan(params).items
  movements.each do |movement|
    september[:total] += movement['amount'].to_f
  end
  [september].to_json
end

post '/api/movements' do
  dynamodb = Aws::DynamoDB::Client.new

  movements = [
    {date: '2016-09-14', amount: '462.73', description: 'mav' },
    {date: '2016-09-15', amount: '7.00', description: 'baf' },
  ]

  movements.each do |movement|
    movement['id'] = rand(1_000_000_000).to_s
  	params = {
      table_name: movements_table,
  		item: movement,
   	}
  	result = dynamodb.put_item(params)
  end

  200
end