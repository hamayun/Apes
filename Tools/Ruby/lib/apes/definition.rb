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
require 'term/ansicolor'

include Term::ANSIColor

class APEDefinition
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def APEDefinition.createFromXML (root)
    name = root.attributes["name"]
    APEDefinition.new(name)
  end

  def to_s
    "definition".red + ' ' + @name.bold
  end

  def == (definition)
    if definition == nil then
      false
    else
      @name == definition.name
    end
  end

  def equ? (definition)
    if definition == nil then
      false
    else
      @name == definition.name
    end
  end

  def hash
    @name.hash
  end
end

