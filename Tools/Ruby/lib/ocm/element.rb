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

class OCMElement
  attr :name
  attr :visibility

  def initialize(arguments)
    @name = arguments.pop
    @visibility = arguments.pop
  end

  def self.createFromXML(node, arguments = [])
    arguments.push(node["visibility"])
    arguments.push(node["name"])
    return self.new(arguments)
  end

  def eql?(e)
    return false if e == nil
    return @name == e.name && @visibility == e.visibility
  end

  def hash
    return [@name, @visibility].hash
  end

  alias :== :eql?
end

