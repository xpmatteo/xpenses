#!/usr/bin/env ruby

$:.push File.dirname(__FILE__) + '/../lib/'

if ARGV.size != 1
  puts "Usage: #{$0} <environment>"
  exit 1
end

require 'infrastructure'
include Infrastructure

@env = ARGV[0]
if ENV['DYNAMODB_ENDPOINT']
  Aws.config.update({ endpoint: ENV['DYNAMODB_ENDPOINT'] })
end


# table names must be unique within region and can't be tagged
# use the convention [component]-[tablename]-[environment]
table_name = "xpenses-movements-#{@env}"
attribute_defs = [
  { attribute_name: 'id',        attribute_type: 'S' },
  { attribute_name: 'date',      attribute_type: 'S' },
]
key_schema = [
  { attribute_name: 'id', key_type: 'HASH' },
  { attribute_name: 'date', key_type: 'RANGE' },
]
request = {
  attribute_definitions:    attribute_defs,
  table_name:               table_name,
  key_schema:               key_schema,
  provisioned_throughput:   { read_capacity_units: 5, write_capacity_units: 5 }
}
create_table table_name, request
