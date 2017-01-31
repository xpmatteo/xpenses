#!/usr/bin/env ruby

$:.push File.dirname(__FILE__) + '/../lib/'

if ARGV.size != 1
  puts "Usage: #{$0} <environment>"
  exit 1
end

require 'infrastructure'
include Infrastructure

@env = ARGV[0]

# role names must be unique per account and can't be tagged
# use the convention [component]-[role]-[environment]
role_name = "xpenses-web-#{@env}"
instance_profile = create_instance_profile_with_policy role_name, {
  policy_arn: 'arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess'
}

# security group names must be unique within the VPC
# use the convention [component]-[role]-[environment]
sg = create_security_group "xpenses-web-#{@env}", @env do |sg|
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

instance_name = 'xpenses-web'
create_instance instance_name, @env, {
  image_id: "ami-211ada4e",
  key_name: $key_name,
  instance_type: "t2.micro",
  security_group_ids: [sg.id],
#  iam_instance_profile: { arn: instance_profile.arn },
 iam_instance_profile: { name: instance_profile.instance_profile_name },
}
print "Publc IP of #{instance_name}: "
puts find_instance(instance_name, @env).public_ip_address


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
