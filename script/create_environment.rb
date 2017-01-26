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

create_instance 'xpenses-host', @env, {
  image_id: "ami-211ada4e",
  key_name: $key_name,
  instance_type: "t2.micro",
  security_group_ids: [sg.id],
}
print "Publc IP of web host: "
puts find_instance('xpenses-host', @env).public_ip_address


table_name = "xpenses_movements_#{@env}"
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
create_table table_name, @env, request
