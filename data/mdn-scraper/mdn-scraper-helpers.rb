require 'net/http'
require 'nokogiri'
require 'pp'

USE_LOCAL_COPY = true

BASE_MDN_URL = 'https://developer.mozilla.org'

def request_interfaces_from_index
  puts 'Requesting interfaces from index...'

  content = nil
  if USE_LOCAL_COPY
    content = File.read('./mdn-html/index.html')
  else
    url = URI('https://developer.mozilla.org/en-US/docs/Web/API')
    content = Net::HTTP.get(url)
  end
  
  html = Nokogiri::HTML(content)
  elements = html.css('.indexListRow code a')
  interfaces = elements.map do |element|
    {
      :name => element.content,
      :description => element['title'],
      :mdn_url => "#{BASE_MDN_URL}#{element['href']}"
    }
  end
  interfaces
end

def complete_interface_data(interface)
  puts "Completing interface data for #{interface[:name]}"

  content = nil
  if USE_LOCAL_COPY
    content = File.read("./mdn-html/interfaces/#{interface[:name]}.html")
  else
    url = URI(interface[:mdn_url])
    content = Net::HTTP.get(url)
  end
  html = Nokogiri::HTML(content)

  properties = parse_properties(html)
  # interface[:properties] = properties || []
  methods = parse_methods(html)
  interface[:methods] = methods || []
end

def get_properties_header(html, index = 0)
  properties_header = html.css('#Properties')[index]
  properties_header = html.css('#Attributes')[index] if !properties_header
  properties_header
end

def get_methods_header(html)
  methods_header = html.css('#Methods')[0]
  # methods_header = html.css('#Attribut  es')[index] if !methods_header
  methods_header
end

def parse_properties(html)
  return nil if !get_properties_header(html)

  properties = try_parse_properties_standard_table(html)
  properties = try_parse_properties_definition_list(html) if !properties
  properties
end

def parse_methods(html)
  header = get_methods_header(html)
  if !header
    p "NO METHODS HEADER"
    return nil
  end

  methods = try_parse_methods_standard_table(html)
  # methods = try_parse_methods_definition_list(html) if !methods
  methods
end

def try_parse_methods_standard_table(html)
  methods_header = get_methods_header(html)
  table = methods_header.next_element
  table = table.next_element if table.name != 'table'
  return nil if table.name != 'table'

  p "HAS METHODS TABLE"

  method_rows = table.css('tbody')[0].element_children
  table_header = table.css('thead tr')[0] || method_rows.shift

  method_rows.each_with_index.map do |method_row, i|
    cells = method_row.css('td')
    method = {}
    method[:name] = cells[0].content
    method
  end.compact
end

def try_parse_properties_standard_table(html)
  properties_header = get_properties_header(html)
  properties_table = properties_header.next_element
  properties_table = properties_table.next_element if properties_table.name != 'table'
  return nil if properties_table.name != 'table'

  property_rows = properties_table.css('tbody')[0].element_children
  table_header = properties_table.css('thead tr')[0] || property_rows.shift
  is_description_in_table = (table_header.element_children.size >= 3)
  type_is_third_cell = !table_header.element_children[1].content.include?('Type')

  property_rows.each_with_index.map do |property_row, i|
    cells = property_row.css('td')
    next if cells.size == 0
    property = {}
    if cells[0].css('code').size > 0
      property[:name] = cells[0].css('code')[0].content.strip
      property[:name] += cells[0].css('code')[1].content.strip if cells[0].css('code')[1]
    else
      property[:name] = cells[0].children[0].content.strip
    end
    type_cell = type_is_third_cell ? cells[2] : cells[1]
    property[:type] = type_cell.content.strip
    property[:readonly] = cells[0].css('.readOnly').size > 0
    property[:obsolete] = cells[0].css('.obsolete').size > 0

    property_link = cells[0].css('a')[0]
    property[:mdn_url] = property_link['href'] if property_link

    if is_description_in_table
      description_cell = type_is_third_cell ? cells[1] : cells[2]
      property[:description] = description_cell.inner_html if description_cell
    else
      description = ''
      property_names = html.css('#Properties ~ h3')
      description_element = property_names[i].next_element
      while description_element.name[0] != 'h'
        description += description_element.to_s
        description_element = description_element.next_element
      end
      property[:description] = description
    end

    property
  end.compact
end

def try_parse_properties_definition_list(html)
  properties_header = get_properties_header(html)
  dl = properties_header.next_element
  dl = dl.next_element if dl.name != 'dl'
  return nil if dl.name != 'dl'

  terms = dl.css('dt')
  definitions = dl.css('dd')
  (0..terms.size - 1).map do |i|
    return nil if !terms[i].css('code')[0]

    {
      :name => terms[i].css('code')[0].content,
      :description => definitions[i].inner_html,
      :readonly => terms[i].css('.readOnly').size > 0,
      :obsolete => terms[i].css('.obsolete').size > 0
    }
  end
end

def download_all_interface_pages
  interfaces = request_interfaces_from_index
  Dir.mkdir('./mdn-html')
  Dir.mkdir('./mdn-html/interfaces')
  interfaces.each do |interface|
    puts "Downloading #{interface[:name]}"
    url = URI(interface[:mdn_url])
    response = Net::HTTP.get(url)
    File.open("./mdn-html/interfaces/#{interface[:name]}.html", 'w') do |file|
      file.write(response)
    end
  end
end

def download_index_page
  url = URI('https://developer.mozilla.org/en-US/docs/Web/API')
  response = Net::HTTP.get(url)
  File.open('./mdn-html/index.html', 'w') { |file| file.write(response) }
end