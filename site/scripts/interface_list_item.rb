require 'string_utils.rb' do

module InterfaceListItem
  CLICKED_INTERFACE = 'clicked interface'

  attr_accessor :interface
  attr_accessor :show_owner_class
  attr_accessor :is_header_clickable

  def self.new
    obj = $window.document.create_element('li')
    obj.extend(self)
    obj.initialize_interface_list_item
    obj
  end

  def interface=(interface)
    @interface = interface

    return if !interface

    class_list.remove('class', 'method', 'attribute')
    class_list.add(interface[:interface_type].to_s)

    update_header
    update_description
    update_declaration
    update_info
  end

  def show_owner_class=(show_owner_class)
    @show_owner_class = show_owner_class
    if @show_owner_class
      class_list.add('show-owner')
    else
      class_list.remove('show-owner')
    end
  end

  def is_header_clickable=(is_clickable)
    @is_header_clickable = is_clickable

    if @is_header_clickable
      class_list.add('clickable')
    else
      class_list.remove('clickable')
    end
  end

  def initialize_interface_list_item
    class_list.add('interface-list-item')

    @title_container = owner_document.create_element('div')
    @title_container.class_list.add('interface-header')
    @owner_class = owner_document.create_element('span')
    @owner_class.class_list.add('owner-class')
    @title_container.append_child(@owner_class)
    @title = owner_document.create_element('span')
    @title.class_list.add('interface-name')
    @title_container.append_child(@title)
    @title_container.onclick = method(:on_click_interface)
    append_child(@title_container)

    @content = owner_document.create_element('div')
    @content.class_list.add('interface-content')
    append_child(@content)

    @description = owner_document.create_element('div')
    @description.class_list.add('description')
    @content.append_child(@description)

    @declaration_container = owner_document.create_element('div')
    @declaration_container.class_list.add('declaration')
    @content.append_child(@declaration_container)

    @declaration = owner_document.create_element('code')
    @declaration.class_list.add('method-signature')
    @declaration_container.append_child(@declaration)

    @method_info = owner_document.create_element('ol')
    @method_info.class_list.add('method-info')
    @declaration_container.append_child(@method_info)

    self.is_header_clickable = true
  end

  private

  def update_header
    interface_name = interface[:name]
    case interface[:interface_type]
    when :attribute, :method
      interface_name = Documentation.underscore(interface_name)
    end
    @title.inner_text = interface_name

    if interface[:owner]
      @owner_class.inner_text = interface[:owner][:name]
    else
      @owner_class.inner_html = ''
    end
  end

  def update_declaration
    type = interface[:interface_type]
    @declaration.inner_html = ''

    return if type == :class

    # FIXME: Link the attribute types, method return types,
    # and method parameter types to the classes.
    return_type_element = owner_document.create_element('span')
    return_type_element.class_list.add('return-type')
    @declaration.append_child(return_type_element)
    @declaration.class_list.add('readonly') if interface[:readonly]

    case type 
    when :method
      return_type_element.inner_text = interface[:return_type]
      append_method_signature
    when :attribute
      return_type_element.inner_text = interface[:type]
      name = owner_document.create_element('span')
      name.inner_text = Documentation.underscore(interface[:name])
      @declaration.append_child(name)
    end
  end

  def append_method_signature
    method_name = owner_document.create_element('span')
    method_name.inner_text = Documentation.underscore(interface[:name])
    @declaration.append_child(method_name)

    parameters = owner_document.create_element('span')
    parameters.class_list.add('parameters')
    interface[:parameters].each do |parameter|
      param_span = owner_document.create_element('span')
      param_span.class_list.add('parameter')
      param_span.inner_text = Documentation.underscore(parameter[:name])
      parameters.append_child(param_span)
    end
    @declaration.append_child(parameters)
  end

  def update_description
    @description.inner_html = interface[:description]
  end

  def update_info
    @method_info.inner_html = ''
    return if interface[:interface_type] != :method

    items = interface[:parameters].dup
    if interface[:return_type] != 'void' and interface[:return_description].size > 0
      items.push({
        :name        => 'return', 
        :type        => interface[:return_type],
        :description => interface[:return_description],
        :is_return   => true
      })
    end

    items.each do |parameter|
      next if parameter[:description].size <= 0

      list_item = owner_document.create_element('li')
      list_item.class_list.add('return') if parameter[:is_return]

      code = owner_document.create_element('code')
      name = owner_document.create_element('span')
      name.class_list.add('parameter-name')
      name.inner_text = Documentation.underscore(parameter[:name])
      code.append_child(name)
      type = owner_document.create_element('span')
      type.class_list.add('parameter-type')
      type.inner_text = parameter[:type]
      code.append_child(type)
      list_item.append_child(code)

      description = owner_document.create_element('div')
      description.class_list.add('parameter-description')
      description.inner_html = parameter[:description]
      list_item.append_child(description)

      @method_info.append_child(list_item)
    end
  end

  def on_click_interface(event)
    return if !is_header_clickable

    click_interface_event = CustomEvent.new(InterfaceListItem::CLICKED_INTERFACE, {:detail => self})
    dispatch_event(click_interface_event)
  end

end # InterfaceListItemView

end # require