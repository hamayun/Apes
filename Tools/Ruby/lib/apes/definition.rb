require 'rexml/document'

class APEDefinition
  attr_reader :name

  def initialize(root)
    @name = root.attributes["name"]
  end

  def to_s
    "definition #{@name}"
  end

  def == (definition)
    if definition == nil then
      false
    else
      @name == definition.name
    end
  end
end

