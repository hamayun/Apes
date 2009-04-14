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

  def initialize(file_path)
    @injected_ids = []
    @restricted_ids = []

    @provided_types = []
    @required_types = []

    @provided_definitions = []
    @required_definitions = []

    @managed_methods = []
    @provided_methods = []
    @required_methods = []

    @path = file_path

    #
    # Get the data
    #

    xml_data = File.new(file_path + "/component.xml")
    file = REXML::Document.new(xml_data)
    root = file.root
    @author = root.attributes["author"]
    @unique = root.attributes["unique"] == "true"
    @wrapper = root.attributes["wrapper"] == "true"

    #
    # Get the component's ID
    #

    root.elements.each("id") do |i|
      @id = APEId.new(i)
    end

    #
    # Get the injected IDs
    #

    root.elements.each("inject/id") do |i|
      id = APEId.new(i)
      if @injected_ids.find { |i| i == id } == nil then
        @injected_ids << id
      else
        abort "Duplicate injected id " + id.to_s + " in component at path " + @path
      end
    end

    #
    # Get the restricted IDs
    #

    root.elements.each("restrict/id") do |i|
      id = APEId.new(i)
      if @restricted_ids.find { |i| i == id } == nil then
        @restricted_ids << id
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
      item = APEMethod.new(m)
      if @managed_methods.find { |i| i == item } == nil then
        @managed_methods << item
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
        item = APEType.new(t)
        if @provided_types.find { |i| i == item } == nil then
          @provided_types << item
        else
          puts item.to_s
          abort "Duplicate provided type" + item.name
        end
      end

      p.elements.each("definition") do |d|
        item = APEDefinition.new(d)
        if @provided_definitions.find { |i| i == item } == nil then
          @provided_definitions << item
        else
          puts item.to_s
          abort "Duplicate provided definition" + item.name
        end
      end

      p.elements.each("method") do |m|
        item = APEMethod.new(m)
        if @provided_methods.find { |i| i == item } == nil then
          @provided_methods << item
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
        item = APEType.new(t)
        if @required_types.find { |i| i == item } == nil then
          @required_types << item
        else
          puts item.to_s
          abort "Duplicate required type" + item.name
        end
      end

      p.elements.each("definition") do |d|
        item = APEDefinition.new(d)
        if @required_definitions.find { |i| i == item } == nil then
          @required_definitions << item
        else
          puts item.to_s
          abort "Duplicate required definition" + item.name
        end
      end

      p.elements.each("method") do |m|
        item = APEMethod.new(m)
        if @required_methods.find { |i| i == item } == nil then
          @required_methods << item
        else
          puts item.to_s
          abort "Duplicate required method" + item.name
        end
      end
    end
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
end

