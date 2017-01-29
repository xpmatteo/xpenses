require 'net/ping'
require 'net/ssh'
require 'minitest/autorun'

require 'infrastructure'

class CreateInstanceTest < Minitest::Test
  include Infrastructure

  def test_create_environment
    @env = "test_#{ENV['USER']}"

    puts " *** creating env"
    sh "script/create_environment.rb #{@env}"
    check_environment_ok

    puts " *** creating env for the second time"
    sh "script/create_environment.rb #{@env}"
    check_environment_ok

    puts " *** destroying env"
    sh "script/destroy_environment.rb #{@env}"
    check_environment_destroyed

    puts " *** destroying env for the second time"
    sh "script/destroy_environment.rb #{@env}"
  end

  private

  def check_environment_ok
    tables = find_all_tables @env
    assert_equal 1, tables.count, "number of tables"

    instances = find_all_live_instances(@env)
    assert_equal ['running'], instances.map{|i| i.state.name}, "instances"
    i = instances.first
    assert_equal "t2.micro", i.instance_type
    assert_match /172\.\d{1,3}\.\d{1,3}\.\d{1,3}/, i.private_ip_address
    assert_match /35\.\d{1,3}\.\d{1,3}\.\d{1,3}/, i.public_ip_address

    check_dynamodb_is_accessible i.public_ip_address
  end

  def check_dynamodb_is_accessible host
    Net::SSH.start(host, 'ec2-user', keys: %w(~/.ssh/aws) ) do |ssh|
      response = ssh.exec!("aws dynamodb --region eu-cental-1 list-tables")
      assert response.include?("xpenses_movements_#{@env}"), "Dynamodb not accessible?\n#{response}"
    end
  end

  def check_environment_destroyed
    instances = find_all_live_instances(@env)
    assert_equal [], instances.map{|i| i.state.name}, "instances"
  end

  def pingable?(host)
    check = Net::Ping::External.new(host)
    check.ping?
  end

  def sh command
    assert system(command), "failed execution of '#{command}'"
  end
end