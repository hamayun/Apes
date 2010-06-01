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

require 'ocm/element'
require 'rubygems'
require 'nokogiri'

class OCMDefinition < OCMElement
  def initialize(name, visibility)
    return super(name, visibility)
  end

  def OCMDefinition.createWith(name, visibility = nil)
    return OCMDefinition.new(name, visibility)
  end

  def OCMDefinition.createFromXML(node)
    name = node["name"]
    visibility = node["visibility"]
    return OCMDefinition.createWith(name, visibility)
  end

  def to_s
    return "definition #{@name} (#{@visibility})"
  end
end

