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
require 'term/ansicolor'

include Term::ANSIColor

class APEArgument
  attr_reader :name, :type, :direction

  def initialize(name, type, direction)
    @name = name
    @type = type
    @direction = direction
  end

  def APEArgument.createFromXML(node)
    name = node["name"]
    type = node["type"]
    direction = node["direction"]
    return APEArgument.new(name, type, direction)
  end

  def to_s
    return @name.underscore + ': ' + @direction.red + ' ' + @type.blue
  end

  def eql?(arg)
    return false unless arg!= nil
    return @name == arg.name && @type == arg.type && @direction == arg.direction
  end

  def hash
    return [@name, @type, @direction].hash
  end

  alias :== :eql?
end

