#!/usr/bin/ruby

$:.push File.dirname(__FILE__) + '/../lib/'

if ARGV.size != 1
  puts "Usage: #{$0} <environment>"
  exit 1
end

require 'infrastructure'
include Infrastructure

@env = ARGV[0]
host = find_instance('xpenses-host', @env)
#system "ssh ec2-user@#{host} -i ~/.ssh/aws"

