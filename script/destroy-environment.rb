#!/usr/bin/env ruby

require_relative 'lib/env-scripts-preamble'

delete_instances @env
find_all_instances(@env).each { |i|
  next if i.state.name == 'terminated'
  puts "Waiting for instance #{i.id} to terminate"
  i.wait_until_terminated
}
delete_security_groups @env
delete_roles @env

# delete tables last, so that we avoid the risk of instances
# keeping a surviving role that points to a deleted table
system "script/create-tables.rb #{@env}" or exit -1
