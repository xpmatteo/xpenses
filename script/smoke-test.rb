#!/usr/bin/env ruby

require 'capybara'
session = Capybara::Session.new(:selenium)

session.visit "http://foo.bar.com/summary"

if session.has_content?("Expenses summary")
  puts "All shiny, captain!"
else
  puts ":( no tagline fonud, possibly something's broken"
  exit(-1)
end

