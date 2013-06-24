require './web-platform-helpers.rb'
require 'nokogiri'

output_dir = ARGV[0] || './'
interfaces = load_interfaces_with_attached_members(output_dir)
parenthetical_interfaces = interfaces.flat_map do |interface|
  with_parentheses = []
  has_parentheses = Proc.new { |o| o[:name].include? '(' or o[:name].include? ')' }
  with_parentheses.push(interface) if has_parentheses[interface]
  methods_with_parentheses = interface[:methods].select { |method| has_parentheses[method] }
  with_parentheses.concat(methods_with_parentheses)
  properties_with_parentheses = interface[:properties].select { |method| has_parentheses[method] }
  with_parentheses.concat(properties_with_parentheses)
  with_parentheses
end

parenthetical_interfaces.each do |interface|
  puts interface[:owner_id] + ' ' + interface[:name]
end

puts parenthetical_interfaces.size