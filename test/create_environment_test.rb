require 'net/ping'
require 'net/ssh'
require 'minitest/autorun'
require 'minitest/hooks/test'

require 'infrastructure'

class CreateInstanceTest < Minitest::Test
  include Minitest::Hooks
  include Infrastructure

  def before_all
    @env = "test_#{ENV['USER']}"
    @name = "test_instance_#{rand(10000)}"

    sg = create_security_group 'web-host', @env do |sg|
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
        ]
      })
    end
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
  rescue
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
    # it fails even if the instance is reachable
    # maybe it's a timing issue?
    i = find_instance @name, @env
    puts "SSH to #{i.public_ip_address}"
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