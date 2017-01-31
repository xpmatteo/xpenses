#!/usr/bin/env ruby

$:.push File.dirname(__FILE__) + '/../lib/'

if ARGV.size != 1
  puts "Usage: #{$0} <environment>"
  exit 1
end

require 'infrastructure'
include Infrastructure

@env = ARGV[0]

delete_roles @env
delete_instances @env
find_all_instances(@env).each { |i|
  next if i.state.name == 'terminated'
  puts "Waiting for instance #{i.id} to terminate"
  i.wait_until_terminated
}
delete_security_groups @env
delete_tables @env

