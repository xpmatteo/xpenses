#!/usr/bin/env ruby

$:.push File.dirname(__FILE__) + '/../lib/'

if ARGV.size != 1
  puts "Usage: #{$0} <environment>"
  exit 1
end

require 'infrastructure'
include Infrastructure

@env = ARGV[0]

puts "Creating instance..."
sg = create_security_group 'xpenses-host', @env do |sg|
  sg.authorize_ingress({
    ip_permissions: [
      {
        ip_protocol: 'icmp',
        from_port: 8,
        to_port: 0,
        ip_ranges: [{ cidr_ip: '0.0.0.0/0' }],
      },
      {
        ip_protocol: 'tcp',
        from_port: 22,
        to_port: 22,
        ip_ranges: [{ cidr_ip: '0.0.0.0/0' }],
      },
      {
        ip_protocol: 'tcp',
        from_port: 80,
        to_port: 80,
        ip_ranges: [{ cidr_ip: '0.0.0.0/0' }],
      },
    ]
  })
end

@instance = create_instance 'xpenses-host', @env, {
  image_id: "ami-211ada4e",
  key_name: $key_name,
  instance_type: "t2.micro",
  security_group_ids: [sg.id],
}



table_name = "xpenses_movements_#{@env}"
puts "Creating table #{table_name}"
dyn = Aws::DynamoDB::Resource.new(region: $region)
if dyn.tables.find { |t| t.table_name == table_name }
  puts "Table #{table_name} already exists"
else
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

  dynamodb_client = Aws::DynamoDB::Client.new(region: $region)
  dynamodb_client.create_table(request)
  dynamodb_client.wait_until(:table_exists, table_name: table_name)
end