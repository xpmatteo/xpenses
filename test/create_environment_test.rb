require 'aws-sdk'
require 'ostruct'

# see api docs here: http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Instance.html
# see examples here: http://docs.aws.amazon.com/sdk-for-ruby/v2/developer-guide/

$region = 'eu-central-1'
$key_name = 'matteo-free'

def make_tags name, env
  { tags: [
      { key: 'Name', value: name },
      { key: 'Env', value: env },
  ]}
end

def create_instance name, env, params
  return if find_instance name, env

  ec2 = Aws::EC2::Resource.new(region: $region)
  defaults = {
    min_count: 1,
    max_count: 1,
  }

  instances = ec2.create_instances(defaults.merge(params))
  instances.batch_create_tags(make_tags(name, env))
  instances.each { |i| i.wait_until_running }
  return instances.first
end

def find_instance name, env
  instances = find_instances(name, env)
  if instances.count == 0
    nil
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
      case i.state.name
      when "terminated"
        # do nothing
      else
        puts "terminating #{i.id} (#{i.state.name})"
        i.terminate
      end
    end
  end
end

def delete_security_groups env
  ec2 = Aws::EC2::Resource.new(region: $region)

  groups = ec2.security_groups({filters: [
    {name: 'tag:Env', values: [env]},
  ]})
  groups.each do |i|
    i.delete
  end
end

require 'net/ping'
require 'net/ssh'
require 'minitest/autorun'
require 'minitest/hooks/test'

class CreateInstanceTest < Minitest::Test
  include Minitest::Hooks

  def before_all
    @env = "test_#{ENV['USER']}"
    @name = "test_instance_#{rand(10000)}"

    ec2 = Aws::EC2::Resource.new(region: $region)

    sg_name = 'web-host'
    sg = ec2.create_security_group({
      group_name: sg_name,
      description: "SG for #{sg_name} in #{@env}",
    })
    sg.create_tags(make_tags(sg_name, @env))
    sg.authorize_ingress({
      ip_permissions: [{
        ip_protocol: 'icmp',
        from_port: 8,
        to_port: 0,
        ip_ranges: [{
          cidr_ip: '0.0.0.0/0'
        }]
      }]
    })

    @instance = create_instance @name, @env, {
      image_id: "ami-211ada4e",
      key_name: $key_name,
      instance_type: "t2.micro",
      security_group_ids: [sg.id],
    }
  end

  def after_all
    delete_instances @env
    delete_security_groups @env
  end

  def test_create_instance
    puts "looking for instance #{@name}"
    i = find_instance @name, @env
    assert i.exists?, "instance should exist"
    assert_equal "running", i.state.name
    assert_equal "ami-211ada4e", i.image_id
    assert_equal "t2.micro", i.instance_type
    assert_equal $key_name, i.key_name
    assert_match /172\.\d{1,3}\.\d{1,3}\.\d{1,3}/, i.private_ip_address
    assert_match /35\.\d{1,3}\.\d{1,3}\.\d{1,3}/, i.public_ip_address
  end

  def test_instance_already_existing
    create_instance @name, @env, {
      image_id: "ami-211ada4e",
      key_name: $key_name,
      instance_type: "t2.micro"
    }
    assert_equal 1, find_instances(@name, @env).count
  end

  def test_can_ping_instance
    i = find_instance @name, @env
    puts "Pinging #{i.public_ip_address}"
    assert pingable?(i.public_ip_address), "instance should be pingable"
  end

  def xtest_can_ssh_instance
    i = find_instance @name, @env
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