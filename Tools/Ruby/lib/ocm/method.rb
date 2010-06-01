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

require 'ocm/argument'
require 'ocm/element'

require 'rubygems'
require 'nokogiri'
require 'term/ansicolor'

include Term::ANSIColor

class OCMMethod < OCMElement
  attr :arguments
  attr :return_type

  def initialize(name, visibility, return_type)
    @arguments = []
    super(name, visibility)
    @return_type = return_type == nil ? "" : return_type
  end

  def OCMMethod.createWith(name, visibility, return_type)
    return OCMMethod.new(name, visibility, return_type)
  end

  def OCMMethod.createFromXML(node)
    name = node["name"]
    visibility = node["visibility"]
    return_type = node["return_type"]
    m = OCMMethod.new(name, visibility, return_type)

    node.xpath("argument").each do |a|
      m.arguments << OCMArgument.createFromXML(a)
    end

    return m
  end

  def to_s
    args = ""
    @arguments.each { |e| args = args + e.to_s + ", " }

    string = @return_type.empty? ? "procedure ".bold : "function ".bold
    string += @name + ' ' + args.chop.chop
    string += ' ' if not args.empty?
    string += "return ".red + @return_type.blue unless @return_type.empty?
    string += " [#{@visibility}]" if @visibility != nil
    return string
  end

  def eql?(m)
    return self.class == NilClass if m == nil
    return m.class == NilClass if self == nil
    return super(m) && @arguments == m.arguments
  end

  def hash
    return [@name, @argument].hash
  end

  alias :== :eql?
end

