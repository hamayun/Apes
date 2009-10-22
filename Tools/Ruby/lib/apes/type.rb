require 'rubygems'
require 'rexml/document'
require 'term/ansicolor'

include Term::ANSIColor

class APEType
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def APEType.createFromXML (root)
    name = root.attributes["name"]
    APEType.new(name)
  end

  def to_s
    'type'.red + ' ' + @name.bold
  end

  def == (type)
    if type == nil then
      false
    else
      @name == type.name
    end
  end

  def equ? (type)
    if type == nil then
      false
    else
      @name == type.name
    end
  end

  def hash
    @name.hash
  end
end

