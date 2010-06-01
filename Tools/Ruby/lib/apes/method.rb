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

require 'apes/argument'

require 'rubygems'
require 'nokogiri'
require 'term/ansicolor'

include Term::ANSIColor

class APEMethod
  attr_reader :name, :arguments, :return_type

  def initialize(name, return_type)
    @arguments = []
    @name = name
    @return_type = return_type == nil ? "" : return_type
  end

  def APEMethod.createFromXML(node)
    name = node["name"]
    return_type = node["return_type"]
    m = APEMethod.new(name, return_type)
    node.xpath("/argument") { |a| m.arguments << APEArgument.createFromXML(a) }
    return m
  end

  def to_s
    args = ""

    @arguments.each { |e| args = args + e.to_s + ", " }

    string = @return_type.empty? ? "procedure ".red : "function ".red
    string += @name.bold + " " + args.chop.chop 
    string += "return ".red + @return_type.blue unless @return_type.empty?
    return string
  end

  def eql?(m)
    return m == nil ? self.class == NilClass :
      (@name == m.name) && (@arguments == m.arguments)
  end

  def hash
    return [@name, @argument].hash
  end

  alias :== :eql?
end

