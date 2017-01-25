require 'minitest/autorun'

require 'aws-sdk'
require 'ostruct'

$region = 'eu-central-1'

def create_instance name, env, params
  ec2 = Aws::EC2::Resource.new(region: $region)
  ec2.create_instances(params)
end

def find_instance name, env
  ec2 = Aws::EC2::Resource.new(region: $region)

  # Get all instances with tag key 'Group'
  # and tag value 'MyGroovyGroup':
  instances= ec2.instances({filters: [
    {name: 'tag:Name', values: [name]},
    {name: 'tag:Env', values: [env]},
  ]})
  if instances.count == 0
    raise "No instances found with name '#{name}' in env '#{env}'"
  else
    return instances.first
  end
end

class CreateEnvironmentTest < Minitest::Test
  def test_create_instance
    create_instance "a", "b", {}

    create_instance "xpenses_host", "test", {
      image_id: "ami-211ada4e",
      associate_public_ip_address: true,
      key_name: "${var.key_name}",
      instance_type: "t2.micro"
    }
#      i.vpc_security_group_ids = ["${aws_security_group.xpenses_host_sg.id}"]

    found_instance = find_instance "xpenses_host", "test"
    assert_equal "ami-211ada4e", found_instance.ami
    assert_match /35\.\d{1-3}\.\d{1-3}\.\d{1-3}/, found_instance.public_ip
  end

  def test_instance_already_existing

  end
end