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
require 'rexml/document'
require 'term/ansicolor'

include Term::ANSIColor

class APEMethod
  attr_reader :name, :arguments, :return_type

  def initialize(name, return_type)
    @arguments = []
    @name = name
    @return_type = return_type
  end

  def APEMethod.createFromXML (root)
    name = root.attributes["name"]
    return_type = root.attributes["return_type"]

    method = APEMethod.new(name, return_type)
    root.elements.each("argument") do |e|
      method.arguments << APEArgument.createFromXML(e)
    end
    
    method
  end

  def to_s
    args = ""

    if @return_type.empty? then
      string = "procedure ".red
    else
      string = "function ".red
    end

    @arguments.each do |e|
      args = args + e.to_s + ", "
    end
    string += @name.bold + " " + args.chop.chop 
    if not @return_type.empty? then string += " - " + "return ".red + @return_type.blue end
    string
  end

  def == (method)
    if method == nil then false
    else (@name == method.name) and (@arguments == method.arguments)
    end
  end

  def equ? (method)
    if method == nil then false
    else (@name == method.name) and (@arguments == method.arguments)
    end
  end

  def hash
    [@name, @argument].hash
  end
end

