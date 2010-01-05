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

