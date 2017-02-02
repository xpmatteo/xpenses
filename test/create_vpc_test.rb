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

    create_vpc name, env, "10.0.0.0/16"
    assert_equal 1, find_all_vpcs(env).count, "after creation"
    vpc = find_vpcs(name, env).first
    assert vpc.vpc_id.start_with?("vpc-")

    create_vpc name, env, "10.0.0.0/16"
    assert_equal 1, find_all_vpcs(env).count, "after second creation attempt"

    destroy_vpc vpc.vpc_id
    assert_equal 0, find_all_vpcs(env).count, "after deletion"
  end
end