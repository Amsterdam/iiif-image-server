#!/usr/bin/env ruby

if ENV['WHITELIST_PATH'].nil?
  raise 'missing env variable: WHITELIST_PATH, usage WHITELIST_PATH=config/stadsarchief_whitelist ./test/test.rb <identifier>'
end

usage_string = 'Usage: ./test.rb <image identifier> <expected url> <expected authorization, default true>'

identifier = ARGV[0]
if !identifier
  raise "No image identifier set. #{usage_string}"
end

expected = ARGV[1]
if !expected
  raise "No expected url. #{usage_string}"
end

def is_true(obj)
  obj.to_s.downcase == "true"
end
expect_is_authorized = ARGV.length <= 2 ? true : is_true(ARGV[2])

require_relative  './delegates'


#
# Actual testing
#

obj = CustomDelegate.new
obj.context = {
  'identifier' => identifier,
  'client_ip' => '127.0.0.1'
}

#
# Checking authorization
#
is_authorized = obj.authorize
if expect_is_authorized == is_authorized
  puts '✓ authorization matches expectation'
else
  puts '✘ authorization does not match expectation'
  puts "expected      :\t#{expect_is_authorized}"
  puts "is_authorized :\t#{is_authorized}"
  raise 'mismatch'
end


#
# Checking resolution
#
puts "Using Source: #{obj.source}" # source dynamically resolved based on identifier

if obj.source == 'FilesystemSource'
  result = obj.filesystemsource_pathname
elsif obj.source == 'HttpSource'
  result = obj.httpsource_resource_info
end

puts "result: '#{result}'"

if result.is_a?(Hash)
  url = result['uri']
else
  url = result
end

if url == expected
  puts '✓ result matches expected url'
else
  puts '✘ mismatch'.encode('utf-8')
  puts "expected:\t'#{expected}'"
  puts "result  :\t'#{url}'"
  raise 'mismatch'
end
