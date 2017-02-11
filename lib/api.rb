require 'sinatra'
require 'json'
require "aws-sdk-core"

require 'account'

set :public_folder, 'public'

get '/' do
  send_file 'public/index.html', type: :html
end

get '/api/summary' do
  content_type :json

  Account.new.summary.to_json
end

post '/api/movements' do
  unless params[:file] &&
         (tmpfile = params[:file][:tempfile]) &&
         (name = params[:file][:filename])
    puts "No file selected"
    return 500
  end

  Account.new.load(tmpfile)
end
