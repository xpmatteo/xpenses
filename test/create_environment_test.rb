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

  instances = ec2.create_instances(defaults.merge(params))
  instance = instances.first
  instance.wait_until_running
  instance.create_tags({ tags: [
    { key: 'Name', value: name },
    { key: 'Env', value: env },
  ]})
  return instance
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

def find_instances name, env
  ec2 = Aws::EC2::Resource.new(region: $region)

  instances= ec2.instances({filters: [
    {name: 'tag:Name', values: [name]},
    {name: 'tag:Env', values: [env]},
  ]})
  return instances
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

require 'net/ping'
require 'net/ssh'
require 'minitest/hooks/test'

class CreateInstanceTest < Minitest::Test
  include Minitest::Hooks

  def before_all
    @name = "test_instance_#{rand(10000)}"
    @instance = create_instance @name, "test", {
      image_id: "ami-211ada4e",
      key_name: $key_name,
      instance_type: "t2.micro"
    }
  end

  def after_all
    delete_instances "test"
  end

  def test_create_instance
    puts "looking for instance #{@name}"
    i = find_instance @name, "test"
    assert_equal "ami-211ada4e", i.image_id
    assert_equal "t2.micro", i.instance_type
    assert_equal $key_name, i.key_name
    assert_match /172\.\d{1,3}\.\d{1,3}\.\d{1,3}/, i.private_ip_address
    assert_match /35\.\d{1,3}\.\d{1,3}\.\d{1,3}/, i.public_ip_address
  end

  def test_instance_already_existing
    create_instance @name, "test", {
      image_id: "ami-211ada4e",
      key_name: $key_name,
      instance_type: "t2.micro"
    }
    assert_equal 1, find_instances(@name, "test").count
  end

  def test_can_ping_instance
    i = find_instance @name, "test"
    puts "Pinging #{i.public_ip_address}"
    assert pingable?(i.public_ip_address), "pingable"
  end

  def xtest_can_ssh_instance
    i = find_instance @name, "test"
    puts "Pinging #{i.public_ip_address}"
    assert sshable?(i.public_ip_address), "pingable"
  end

  private

  def pingable?(host)
      check = Net::Ping::External.new(host)
      check.ping?
  end

  def sshable? host
    puts "SSHing #{host} ..."
    Net::SSH.start(host.to_s, 'ec2-user', :password => 'badpassword' ) do |ssh|
      p ssh
    end
  end

end