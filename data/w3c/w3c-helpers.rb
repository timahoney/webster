require 'nokogiri'
require 'pp'

def replace_existing_interface(interfaces, interface)
  existing_interface = interfaces[interface[:name]]
  if !existing_interface
    interfaces[interface[:name]] = interface
  else
    interface[:attributes].each_value do |attribute|
      existing_interface[:attributes][attribute[:name]] = attribute
    end

    interface[:methods].each_value do |method|
      existing_interface[:methods][method[:name]] = method
    end
    
    existing_interface[:description] = interface[:description]
  end
end

def parse_attribute(xml_attribute)
  attribute = {}
  attribute[:name] = xml_attribute['name']
  attribute[:id] = attribute[:name]
  attribute[:type] = xml_attribute['type']
  attribute[:description] = xml_attribute.css('descr')[0].inner_html
  attribute[:readonly] = xml_attribute['readonly'] == 'yes'
  attribute
end

def parse_method(xml_method)
  method = {}
  method[:name] = xml_method['name']
  method[:id] = method[:name]
  method[:description] = xml_method.css('descr')[0].inner_html
  returns = xml_method.css('returns')[0]
  method[:return_type] = returns['type']
  method[:return_description] = returns.css('descr')[0].inner_html
  method[:parameters] = xml_method.css('param').map do |xml_parameter|
    parameter = {}
    parameter[:name] = xml_parameter['name']
    parameter[:type] = xml_parameter['type']
    parameter[:description] = xml_parameter.css('descr')[0].inner_html
    parameter
  end

  method
end

def parse_interface(xml_interface)
  interface = {}
  interface[:name] = xml_interface['name']
  interface[:id] = interface[:name]
  interface[:parent_id] = xml_interface['parent'] || xml_interface['inherits']
  interface[:parent_id] = 'EventTarget' if interface[:name] == 'Node'
  interface[:description] = xml_interface.css('descr')[0].inner_html
  interface[:attributes] = {}
  interface[:methods] = {}

  xml_interface.css('attribute').each do |xml_attribute|
    attribute = parse_attribute(xml_attribute)
    attribute[:owner_id] = interface[:name]
    interface[:attributes][attribute[:name]] = attribute
  end

  xml_interface.css('method').each do |xml_method|
    method = parse_method(xml_method)
    method[:owner_id] = interface[:name]
    interface[:methods][method[:name]] = method
  end

  interface
end

def parse_interfaces_from_filename(filename)
  content = File.read(filename)
  xml = Nokogiri::XML(content)
  xml_interfaces = xml.css('interface')
  xml_interfaces.map { |xml_interface| parse_interface(xml_interface) }
end

def build_xml(interfaces)
  puts 'Building XML...'
  builder = Nokogiri::XML::Builder.new do |xml|
    xml.interfaces {
      interfaces.each do |interface|

        interface_attributes = {}
        interface_attributes[:id] = interface[:id]
        interface_attributes[:name] = interface[:name]
        interface_attributes[:description] = interface[:description]
        interface_attributes[:parent_id] = interface[:parent_id] if interface[:parent_id]

        xml.interface(interface_attributes) {

          xml.methods_ {

            interface[:methods].each do |method|
              method_attributes = {}
              method_attributes[:id] = method[:id]
              method_attributes[:name] = method[:name]
              method_attributes[:return_type] = method[:return_type]
              method_attributes[:owner_id] = method[:owner_id]
              method_attributes[:description] = method[:description]
              method_attributes[:return_description] = method[:return_description]
              xml.method_(method_attributes) {

                method[:parameters].each do |parameter|
                  parameter_attributes = {}
                  parameter_attributes[:id] = parameter[:id]
                  parameter_attributes[:name] = parameter[:name]
                  parameter_attributes[:type] = parameter[:type]
                  parameter_attributes[:owner_id] = parameter[:owner_id]
                  parameter_attributes[:description] = parameter[:description]
                  parameter_attributes[:optional] = parameter[:optional] if parameter[:optional]
                  xml.parameter(parameter_attributes)
                end
              }
            end
          } # methods

          xml.properties {
            interface[:attributes].each { |property| xml.property_(property) }
          } # properties

        }

      end # interfaces
    }
  end
  
  builder.to_xml
end