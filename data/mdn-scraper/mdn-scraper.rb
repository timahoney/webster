require './mdn-scraper-helpers.rb'
require 'json'
require 'pp'

TEST_INTERFACE_COUNT = 1

interfaces = request_interfaces_from_index()
# page = 2
# start = (TEST_INTERFACE_COUNT * page) - TEST_INTERFACE_COUNT
# interfaces = interfaces[start...start+TEST_INTERFACE_COUNT]
# interfaces = interfaces.select { |interface| interface[:name].start_with? 'Element' }
# interfaces = interfaces.take(TEST_INTERFACE_COUNT)

interfaces.each do |interface|
  complete_interface_data(interface)
end

File.open("mdn-interfaces.json", 'w') do |file|
  file.write(JSON.pretty_generate(interfaces))
end