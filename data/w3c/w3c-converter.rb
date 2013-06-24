require './w3c-helpers.rb'
require 'json'

filenames = ['./xml/DOM1/', './xml/DOM2/', './xml/DOM3/'].flat_map do |dir| 
  dir_filenames = Dir.new(dir).entries
  dir_filenames.delete_if { |filename| filename[0] == '.' }
  dir_filenames.map { |filename| dir + filename }
end

interfaces = {}

filenames.each do |filename|
  file_interfaces  = parse_interfaces_from_filename(filename)
  file_interfaces.each { |interface| replace_existing_interface(interfaces, interface) }
end

# Replace hashes with arrays
interfaces = interfaces.values
interfaces.each do |interface|
  interface[:attributes] = interface[:attributes].values
  interface[:methods] = interface[:methods].values
end

File.open('./w3c-interfaces.json', 'w') { |file| file.write(JSON.pretty_generate(interfaces)) }
File.open('./w3c-interfaces.xml', 'w') { |file| file.write(build_xml(interfaces)) }