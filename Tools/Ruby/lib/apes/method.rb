require 'rexml/document'
require 'apes/argument'

class APEMethod
  attr_reader :name, :arguments, :return_type

  def initialize(root)
    @arguments = []
    @name = root.attributes["name"]
    @return_type = root.attributes["return_type"]

    root.elements.each("argument") do |e|
      @arguments << APEArgument.new(e)
    end
  end

  def to_s
    args = ""

    if @return_type.empty? then
      string = "procedure "
    else
      string = "function "
    end

    @arguments.each do |e|
      args = args + e.to_s + ", "
    end
    string += @name + " (" + args.chop.chop + ")"
    if not @return_type.empty? then string += " return " + @return_type end
    string
  end

  def == (method)
    if method == nil then false
    else (@name == method.name) and (@arguments == method.arguments)
    end
  end
end

