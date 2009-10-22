require 'rubygems'
require 'rexml/document'
require 'term/ansicolor'

include Term::ANSIColor

class APEDefinition
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def APEDefinition.createFromXML (root)
    name = root.attributes["name"]
    APEDefinition.new(name)
  end

  def to_s
    "definition".red + ' ' + @name.bold
  end

  def == (definition)
    if definition == nil then
      false
    else
      @name == definition.name
    end
  end

  def equ? (definition)
    if definition == nil then
      false
    else
      @name == definition.name
    end
  end

  def hash
    @name.hash
  end
end

