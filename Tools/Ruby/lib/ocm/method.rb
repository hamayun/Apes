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
require 'pp'

class OCMMethod < OCMElement
  attr :arguments, true
  attr :return_type

  def initialize(*args)
    super(*args)
    @arguments = []
    @return_type = return_type == nil ? "" : args[2]
  end

  def self.createFromXML(node, *args)
    return_type = node["return_type"]
    method = super(node, *(args << return_type))
    node.xpath("argument").each { |a| method.arguments << OCMArgument.new(a) }
    return method
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

