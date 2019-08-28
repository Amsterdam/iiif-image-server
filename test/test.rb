#!/usr/bin/env ruby

require_relative  '../config/delegates'

identifier = ARGV[0]

if !identifier
  raise 'No image identifier set. Usage: ./test.rb <image identifier>'
end

obj = CustomDelegate.new
obj.context = {
  'identifier' => identifier,
  'client_ip' => '127.0.0.1'
}

puts "Using Source: #{obj.source}"

if obj.source == 'FilesystemSource'
  puts "  #{obj.filesystemsource_pathname}"
elsif obj.source == 'HttpSource'
  puts obj.httpsource_resource_info
end
