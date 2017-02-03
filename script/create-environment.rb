#!/usr/bin/env ruby

require_relative 'lib/env-scripts-preamble'

vpc = create_vpc "xpenses", @env, "10.0.0.0/16"

system "script/create-tables.rb #{@env}" or exit -1

# role names must be unique per account and can't be tagged
# use the convention [component]-[role]-[environment]
role_name = "xpenses-web-#{@env}"

policy_for_web_host = <<EOS
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DescribeQueryScanBooksTable",
            "Effect": "Allow",
            "Action": [
                "dynamodb:DescribeTable",
                "dynamodb:Query",
                "dynamodb:PutItem",
                "dynamodb:Scan"
            ],
            "Resource": "#{find_table(table_name).table_arn}"
        }
    ]
}
EOS
instance_profile = create_instance_profile_with_policy role_name, policy_for_web_host

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
  iam_instance_profile: { name: instance_profile.instance_profile_name },
}
print "Publc IP of #{instance_name}: "
puts find_instance(instance_name, @env).public_ip_address

