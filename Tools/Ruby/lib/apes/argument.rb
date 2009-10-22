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

