require 'rexml/document'
require 'term/ansicolor'

include Term::ANSIColor

class APEArgument
  attr_reader :name, :type, :direction

  def initialize(name, type, direction)
    @name = name
    @type = type
    @direction = direction
  end

  def APEArgument.createFromXML (root)
    name = root.attributes["name"]
    type = root.attributes["type"]
    direction = root.attributes["direction"]

    APEArgument.new(name, type, direction)
  end

  def to_s
    @name.underscore + ': ' + @direction.red + ' ' + @type.blue
  end

  def == (argument)
    if argument == nil then
      false
    else
      ((@name == argument.name) and (@type == argument.type) \
       and (@direction == argument.direction))
    end
  end

  def equ? (argument)
    if argument == nil then
      false
    else
      ((@name == argument.name) and (@type == argument.type) \
       and (@direction == argument.direction))
    end
  end

  def hash
    [@name, @type, @direction].hash
  end
end

