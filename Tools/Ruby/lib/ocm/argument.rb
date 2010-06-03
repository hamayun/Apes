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

class OCMArgument
  attr :name
  attr :type
  attr :direction

  def initialize(name, type, direction)
    @name = name
    @type = type
    @direction = direction
  end

  def self.createFromXML(node)
    name = node["name"]
    type = node["type"]
    dir = node["direction"]
    return self.new(name, type, dir)
  end

  def to_s
    return @name.underscore + ': ' + @direction.to_s.red + ' ' + @type.blue
  end

  def eql?(arg)
    return false if arg == nil
    return @name == arg.name && @type == arg.type && @direction == arg.direction
  end

  def hash
    return [@name, @type, @direction].hash
  end

  private

  alias :== :eql?
end

