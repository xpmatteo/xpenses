require 'net/ssh'
require 'minitest/autorun'

require 'infrastructure'

class CreateInstanceTest < Minitest::Test
  include Infrastructure

  def test_create_environment
    @env = "test_#{ENV['USER']}"

    puts " *** creating env"
    sh "script/create-environment.rb #{@env}"
    check_environment_ok

    puts " *** creating env for the second time"
    sh "script/create-environment.rb #{@env}"
    check_environment_ok

    puts " *** destroying env"
    sh "script/destroy-environment.rb #{@env}"
    check_environment_destroyed

    puts " *** destroying env for the second time"
    sh "script/destroy-environment.rb #{@env}"
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
    tries ||= 2
    Net::SSH.start(host, 'ec2-user', keys: %w(~/.ssh/aws) ) do |ssh|
      query = %[aws dynamodb query --table-name xpenses-movements-#{@env} --key-condition-expression 'id = :v' --expression-attribute-values '{":v": {"S": "0"}}']
      response = ssh.exec!("#{query} --region #{$region}")
      assert response.include?('"Count": 0'), "Dynamodb not accessible?\n#{response}"
    end
  rescue
    unless (tries -= 1).zero?
    puts "Retrying..."
      sleep 5
      retry
    else
      fail
    end
  end

  def check_environment_destroyed
    instances = find_all_live_instances(@env)
    assert_equal [], instances.map{|i| i.state.name}, "instances"
    assert_nil find_instance_profile("xpenses-web-#{@env}"), "instance profile"
    assert_nil find_role("xpenses-web-#{@env}"), "role"
    assert_nil find_table("xpenses-movements-#{@env}"), "table"
  end

  def sh command
    assert system(command), "failed execution of '#{command}'"
  end
end