require 'net/ssh'
require 'minitest/autorun'

require 'infrastructure'

class CreateVpcTest < Minitest::Test
  include Infrastructure

  def test_create_vpc
    env = "test-#{ENV['USER']}"
    name = "myvpc"

    destroy_all_vpcs env
    assert_equal 0, find_all_vpcs(env).count, "initial count"

    vpc = create_vpc name, env, "10.0.0.0/16"
    assert_equal 1, find_all_vpcs(env).count, "after creation"
    assert vpc.vpc_id.start_with?("vpc-")

    vpc1 = find_vpcs(name, env).first
    assert_equal vpc.vpc_id, vpc1.vpc_id

    vpc2 = create_vpc name, env, "10.0.0.0/16"
    assert_equal 1, find_all_vpcs(env).count, "after second creation attempt"
    assert_equal vpc.vpc_id, vpc2.vpc_id

    destroy_vpc vpc.vpc_id
    assert_equal 0, find_all_vpcs(env).count, "after deletion"
  end


  def test_create_subnet
    env = "test-#{ENV['USER']}"
    subnet_name = "mysubnet"

    destroy_all_vpcs env

    vpc = create_vpc "tmp", env, "10.0.0.0/16"
    subnet = create_subnet subnet_name, env, vpc.vpc_id, "10.0.1.0/24"
    assert_equal 1, find_all_subnets(env).count, "after creation"
    assert subnet.subnet_id.start_with?("vpc-")

  end
end