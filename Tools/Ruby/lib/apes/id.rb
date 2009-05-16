require 'rexml/document'

class APEId
  attr_reader :name, :short_name, :version

  def initialize (name, short_name, version)
    @name = name
    @short_name = short_name
    @version = version

    if @short_name == nil then @short_name = @name end
  end

  def APEId.createFromXML (root)
    name = root.attributes["name"]
    short_name = root.attributes["short_name"]
    version = root.attributes["version"]

    APEId.new(name, short_name, version)
  end

  def to_s
    "#{@name} [#{@version}]"
  end

  def == (id)
    if id == nil then
      false
    else
      @name == id.name and @version == id.version
    end
  end

  def eql? (id)
    if id == nil then
      false
    else
      @name == id.name and @version == id.version
    end
  end

  def hash
    [@name, @version].hash
  end
end

