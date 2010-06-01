# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'rubygems'
require 'nokogiri'

class APEId
  attr_reader :name, :short_name, :version

  def initialize (name, short_name, version)
    @name = name
    @short_name = short_name
    @version = version

    if @short_name == nil then @short_name = @name end
  end

  def APEId.createFromXML(node)
    name = node["name"]
    short_name = node["short_name"]
    version = node["version"]
    return APEId.new(name, short_name, version)
  end

  def to_s
    return "#{@name} [#{@version}]"
  end

  def eql?(id)
    return id == nil ? false : @name == id.name && @version == id.version
  end

  def hash
    return [@name, @version].hash
  end

  alias :== :eql?
end

