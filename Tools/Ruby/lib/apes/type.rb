require 'rexml/document'

class APEType
  attr_reader :name

  def initialize(root)
    @name = root.attributes["name"]
  end

  def to_s
    "type #{@name}"
  end

  def == (type)
    if type == nil then
      false
    else
      @name == type.name
    end
  end
end

