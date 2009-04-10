require 'rexml/document'

class APEId
  attr_reader :name, :short_name, :version

  def initialize(root)
    @name = root.attributes["name"]
    @short_name = root.attributes["short_name"]
    @version = root.attributes["version"]

    if @short_name == nil then @short_name = @name end
  end

  def to_s
    "{#{@name}, v#{@version}}"
  end

  def == (id)
    if id == nil then
      false
    else
      @name == id.name and @version == id.version
    end
  end
end

