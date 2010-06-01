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

require 'apes/id'
require 'apes/type'
require 'apes/definition'
require 'apes/method'

require 'rubygems'
require 'nokogiri'
require 'pp'

class APEComponent
  attr_reader :unique, :id, :wrapper
  attr_reader :author, :path, :types, :ids
  attr_reader :defs, :methods

  def initialize(file_path, id, author, unique, wrapper)
    @path = file_path
    @id = id
    @author = author
    @unique = unique
    @wrapper = wrapper

    @ids = { 'inject' => [], 'restrict' => [] }
    @types = { 'provide' => [], 'require' => [] }
    @defs = { 'provide' => [], 'require' => [] }
    @methods = { 'provide' => [], 'require' => [] }
  end

  def APEComponent.createFromXMLFileAtPath(path)
    # Get the XML data from the input file.
    #

    document = nil
    File.open(path + '/component.xml') { |f| document = Nokogiri.XML(f) }
    author, unique, wrapper = "", "", ""

    author = document.root["author"]
    unique = document.root["unique"] == "true"
    wrapper = document.root["wrapper"] == "true"

    #
    # Get the component's ID
    #

    ids = []
    document.xpath("/component/id").each { |n| ids << APEId.createFromXML(n) }

    abort "[component] no ID for component at " + path if ids.length == 0 
    abort "[component] too many IDs for component at " + path if ids.length > 1

    cmp = APEComponent.new(path, ids.first, author, unique, wrapper)

    #
    # Get the injected IDs
    #

    document.xpath("/component/inject/id").each do |node|
      id = APEId.createFromXML(node)
      cmp.ids['inject'] << id unless cmp.ids['inject'].include?(id)
    end

    #
    # Get the restricted IDs
    #

    document.xpath("/component/restrict/id").each do |node|
      id = APEId.createFromXML(node)
      cmp.ids['restrict'] << id unless cmp.ids['restrict'].include?(id)
    end

    #
    # Get the provided items
    #

    document.xpath("/component/provide/type").each do |node|
      t = APEType.createFromXML(node)
      cmp.types['provide'] << t unless cmp.types['provide'].include?(t) 
    end

    document.xpath("/component/provide/definition").each do |node|
      d = APEDefinition.createFromXML(node)
      cmp.defs['provide'] << d unless cmp.defs['provide'].include?(d) 
    end

    document.xpath("/component/provide/method").each do |node|
      m = APEMethod.createFromXML(node)
      cmp.methods['provide'] << m unless cmp.methods['provide'].include?(m)
    end

    #
    # Get the required items
    #

    document.xpath("/component/require/type").each do |node|
      t = APEType.createFromXML(node)
      cmp.types['require'] << t unless cmp.types['require'].include?(t) 
    end

    document.xpath("/component/require/definition").each do |node|
      d = APEDefinition.createFromXML(node)
      cmp.defs['require'] << d unless cmp.defs['require'].include?(d) 
    end

    document.xpath("/component/require/method").each do |node|
      m = APEMethod.createFromXML(node)
      cmp.methods['require'] << m unless cmp.methods['require'].include?(m)
    end

    return cmp
  end

  def overlap?(c)
    union = (@methods["provide"] + c.methods["provide"]).uniq
    total_length = @methods["provide"].length + c.methods["provide"].length
    return true if union.length < total_length

    union = (@types["provide"] + c.types["provide"]).uniq
    total_length = @types["provide"].length + c.types["provide"].length
    return true if union.length < total_length

    union = (@defs["provide"] + c.defs["provide"]).uniq
    total_length = @defs["provide"].length + c.defs["provide"].length
    return true if union.length < total_length

    return false
  end

  def eql?(c)
    return c == nil ? self.class == NilClass : @id == c.id
  end

  def ==(c)
    return self.eql?(c)
  end

  def hash
    return @id.hash
  end
end

