require 'rexml/document'
require 'apes/id'
require 'apes/type'
require 'apes/definition'
require 'apes/method'

class APEComponent
  attr_reader :unique, :id, :wrapper, :injected_ids, :restricted_ids
  attr_reader :author, :path, :provided_types, :required_types
  attr_reader :provided_definitions, :required_definitions
  attr_reader :managed_methods, :provided_methods, :required_methods

  def initialize(file_path, id, author, unique, wrapper)
    @path = file_path
    @id = id
    @author = author
    @unique = unique
    @wrapper = wrapper

    @injected_ids = []
    @restricted_ids = []

    @provided_types = []
    @required_types = []

    @provided_definitions = []
    @required_definitions = []

    @managed_methods = []
    @provided_methods = []
    @required_methods = []
  end

  def APEComponent.createFromXMLFileAtPath(file_path)
    
    #
    # Get the data
    #

    xml_data = File.new(file_path + "/component.xml")
    file = REXML::Document.new(xml_data)
    root = file.root
    author = root.attributes["author"]
    unique = root.attributes["unique"] == "true"
    wrapper = root.attributes["wrapper"] == "true"
  
    #
    # Get the component's ID
    #
    
    ids = []
    root.elements.each("id") do |i|
      ids << APEId.createFromXML(i)
    end

    if ids.length == 0 then
      abort "[component] no ID found for component at " + file_path
    elsif ids.length > 1 then
      abort "[component] too many IDs found for component at " + file_path
    end

    component = APEComponent.new(file_path, ids[0], author, unique, wrapper)

    #
    # Get the injected IDs
    #

    root.elements.each("inject/id") do |i|
      id = APEId.createFromXML(i)
      if component.injected_ids.find { |i| i == id } == nil then
        component.injected_ids << id
      else
        abort "Duplicate injected id " + id.to_s + " in component at " + @path
      end
    end

    #
    # Get the restricted IDs
    #

    root.elements.each("restrict/id") do |i|
      id = APEId.createFromXML(i)
      if component.restricted_ids.find { |i| i == id } == nil then
        component.restricted_ids << id
      else
        puts "Component at path:"
        puts "\t" + @path
        abort "Duplicate restricted id: " + id.to_s
      end
    end

    #
    # Get the managed methods
    #

    root.elements.each("manage/method") do |m|
      item = APEMethod.createFromXML(m)
      if component.managed_methods.find { |i| i == item } == nil then
        component.managed_methods << item
      else
        puts id.to_s
        abort "Duplicate managed method:" + item.name
      end
    end

    #
    # Get the provided items
    #

    root.elements.each("provide") do |p|
      p.elements.each("type") do |t|
        item = APEType.createFromXML(t)
        if component.provided_types.find { |i| i == item } == nil then
          component.provided_types << item
        else
          puts item.to_s
          abort "Duplicate provided type" + item.name
        end
      end

      p.elements.each("definition") do |d|
        item = APEDefinition.createFromXML(d)
        if component.provided_definitions.find { |i| i == item } == nil then
          component.provided_definitions << item
        else
          puts item.to_s
          abort "Duplicate provided definition" + item.name
        end
      end

      p.elements.each("method") do |m|
        item = APEMethod.createFromXML(m)
        if component.provided_methods.find { |i| i == item } == nil then
          component.provided_methods << item
        else
          puts item.to_s
          abort "Duplicate provided method" + item.name
        end
      end
    end

    #
    # Get the required items
    #

    root.elements.each("require") do |p|
      p.elements.each("type") do |t|
        item = APEType.createFromXML(t)
        if component.required_types.find { |i| i == item } == nil then
          component.required_types << item
        else
          puts item.to_s
          abort "Duplicate required type" + item.name
        end
      end

      p.elements.each("definition") do |d|
        item = APEDefinition.createFromXML(d)
        if component.required_definitions.find { |i| i == item } == nil then
          component.required_definitions << item
        else
          puts item.to_s
          abort "Duplicate required definition" + item.name
        end
      end

      p.elements.each("method") do |m|
        item = APEMethod.createFromXML(m)
        if component.required_methods.find { |i| i == item } == nil then
          component.required_methods << item
        else
          puts item.to_s
          abort "Duplicate required method" + item.name
        end
      end
    end

    component
  end

  def overlap?(component)
    overlap = false

    if component != self  then
      @provided_types.each do |t|
        item = component.provided_types.find { |f| t == f }
        overlap = (overlap or (item != nil))
      end

      @provided_definitions.each do |d|
        item = component.provided_definitions.find { |f| d == f }
        overlap = (overlap or (item != nil))
      end

      @provided_methods.each do |m|
        item = component.provided_methods.find { |f| m == f }
        overlap = (overlap or (item != nil))
      end
    end
  
    overlap
  end

  def equ?(component)
    @id == component.id
  end

  def hash
    @id.hash
  end
end

