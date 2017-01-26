#!/usr/bin/env ruby

$:.push File.dirname(__FILE__) + '/../lib/'

if ARGV.size != 1
  puts "Usage: #{$0} <environment>"
  exit 1
end

require 'infrastructure'
include Infrastructure

@env = ARGV[0]

puts "Deleting instances..."
delete_instances @env
puts "Waiting until all instances are terminated..."
find_all_instances(@env).each { |i| i.wait_until_terminated  }
puts "Deleting security groups..."
delete_security_groups @env
puts "Deleting tables..."
delete_tables @env

