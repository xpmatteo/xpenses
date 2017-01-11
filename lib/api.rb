require 'sinatra'
require 'json'

get '/api/summary' do
  content_type :json
  { month: '2016-09', total: '750.53'}.to_json
end
