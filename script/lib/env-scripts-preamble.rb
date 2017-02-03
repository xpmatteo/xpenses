
require "aws-sdk-core"


$:.push File.dirname(__FILE__) + '/../../lib/'

if ARGV.size != 1
  puts "Usage: #{$0} <environment>"
  exit 1
end

@env = ARGV[0]
if ENV['DYNAMODB_ENDPOINT']
  Aws.config.update({ endpoint: ENV['DYNAMODB_ENDPOINT'] })
end

require 'infrastructure'
include Infrastructure

