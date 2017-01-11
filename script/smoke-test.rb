#!/usr/bin/env ruby

require 'capybara'
session = Capybara::Session.new(:selenium)

session.visit "http://test.xpenses.it.s3-website.eu-central-1.amazonaws.com/"

if session.has_content?("Expenses summary")
  puts "All shiny, captain!"
else
  puts ":( no tagline fonud, possibly something's broken"
  exit(-1)
end

