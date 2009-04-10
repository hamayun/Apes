require 'rexml/document'

class APEArgument
  attr_reader :name, :type, :direction

  def initialize(root)
    @name = root.attributes["name"]
    @type = root.attributes["type"]
    @direction = root.attributes["direction"]
  end

  def to_s
    "#{@name}: #{@direction} #{@type}"
  end

  def == (argument)
    if argument == nil then
      false
    else
      ((@name == argument.name) and (@type == argument.type) \
       and (@direction == argument.direction))
    end
  end
end

