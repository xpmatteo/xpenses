require 'minitest/autorun'

require 'aws-sdk'
require 'ostruct'

# see docs here: http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Instance.html

$region = 'eu-central-1'
$key_name = 'matteo-free'

def create_instance name, env, params
  ec2 = Aws::EC2::Resource.new(region: $region)
  defaults = {
    min_count: 1,
    max_count: 1,
  }

  instance = ec2.create_instances(defaults.merge(params))
  instance.first.wait_until_running
  instance.first.create_tags({ tags: [
    { key: 'Name', value: name },
    { key: 'Env', value: env },
  ]})
  return instance.first
end

def find_instance name, env
  ec2 = Aws::EC2::Resource.new(region: $region)

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

def delete_instances env
  ec2 = Aws::EC2::Resource.new(region: $region)

  instances= ec2.instances({filters: [
    {name: 'tag:Env', values: [env]},
  ]})
  instances.each do |i|
    if i.exists?
      case i.state.code
      when 48  # terminated
        puts "#{i} is already terminated"
      else
        puts "terminating #{i}"
        i.terminate
      end
    end
  end
end

class CreateEnvironmentTest < Minitest::Test

  def setup
    @name = "test_instance_#{rand(10000)}"
    @instance = create_instance @name, "test", {
      image_id: "ami-211ada4e",
      key_name: $key_name,
      instance_type: "t2.micro"
    }
  end

  def teardown
    delete_instances "test"
  end

  def test_create_instance
    i = find_instance @name, "test"
    p i.state.name
    assert_equal "ami-211ada4e", i.image_id
    assert_equal "t2.micro", i.instance_type
    assert_equal $key_name, i.key_name
    assert_match /172\.\d{1,3}\.\d{1,3}\.\d{1,3}/, i.private_ip_address
    assert_match /35\.\d{1,3}\.\d{1,3}\.\d{1,3}/, i.public_ip_address
  end

  def xtest_instance_already_existing

  end
end