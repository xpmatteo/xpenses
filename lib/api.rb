require 'sinatra'
require 'json'

get '/' do
  send_file 'public/index.html', type: :html
end

get '/api/summary' do
  content_type :json
  [{ month: '2016-09', total: '750.53'}].to_json
end

