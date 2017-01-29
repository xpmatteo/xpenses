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
    sh "script/create_environment.sh #{@env}"
  end

  def after_all
    system "script/destroy_environment.sh #{@env}"
  end

  def test_create_environment
    assert_equal 1, find_instances(@env).count
    puts "looking for instance #{@name}"
    i = find_instance @name, @env
    assert i.exists?, "instance should exist"
    assert_equal "running", i.state.name
    assert_equal "t2.micro", i.instance_type
    assert_match /172\.\d{1,3}\.\d{1,3}\.\d{1,3}/, i.private_ip_address
    assert_match /35\.\d{1,3}\.\d{1,3}\.\d{1,3}/, i.public_ip_address
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

  def sh command
    assert system(command), "failed execution of '#{command}'"
  end
end