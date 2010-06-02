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

require 'ocm/id'
require 'ocm/type'
require 'ocm/definition'
require 'ocm/method'
require 'ocm/set'
require 'ocm/variable'

require 'rubygems'
require 'nokogiri'
require 'term/ansicolor'
include Term::ANSIColor

class OCMInterface
  attr :author
  attr :id
  attr :ids
  attr :inheritFrom
  attr :path
  attr :provide
  attr :require
  attr :unique
  attr :wrapper

  #
  # Initialization method.
  #

  def initialize(path, id, author, unique, wrapper, inheritFrom)
    @author = author
    @id = id
    @path = path
    @unique = unique
    @wrapper = wrapper
    @inheritFrom = inheritFrom

    @ids = { 'inject' => [], 'restrict' => [] }
    @provide = OCMSet.new
    @require = OCMSet.new
  end

  #
  # Class method to instantiate an interface
  # from a Nokogir NodeSet.
  #

  def OCMInterface.createFromXMLFileAtPath(path)
    xml = nil
    root, context = "interface", "context"

    #
    # Get the XML data from the input file.
    #

    begin
      File.open(path + '/' + root + '.xml') { |f| xml = Nokogiri.XML(f) }
    rescue Errno::ENOENT
      if root == "interface" then
        root, context = "component", ""
        retry
      else
        return nil
      end
    end

    author = xml.root["author"]
    unique = xml.root["unique"] == "true"
    wrapper = xml.root["wrapper"] == "true"
    inheritFrom = xml.root["inheritFrom"]

    #
    # Get the interface's ID
    #

    ids = []
    xml.xpath("/#{root}/id").each { |n| ids << OCMId.createFromXML(n) }

    abort "[interface] no ID for interface at " + path if ids.length == 0 
    abort "[interface] too many IDs for interface at " + path if ids.length > 1

    iface = OCMInterface.new(path, ids[0], author, unique, wrapper, inheritFrom)

    #
    # Get the injected IDs
    #

    xml.xpath("/#{root}/inject/id").each do |node|
      id = OCMId.createFromXML(node)
      iface.ids['inject'] << id unless iface.ids['inject'].include?(id)
    end

    #
    # Get the restricted IDs
    #

    xml.xpath("/#{root}/restrict/id").each do |node|
      id = OCMId.createFromXML(node)
      iface.ids['restrict'] << id unless iface.ids['restrict'].include?(id)
    end

    #
    # Get the different items
    #

    ROLES.each do |role|
      SECTIONS.each do |key, value|
        xpath = "/#{root}/#{role}/#{context}/#{key}"
        xml.xpath(xpath).each do |node|
          t = value.createFromXML(node)
          v = iface.instance_variable_get(('@' + role).to_sym)
          v[key] << t unless v[key].include?(t) 
        end
      end
    end

    return iface
  end

  #
  # Compute the direct dependences of the interface.
  #

  def computeDependences(list)
    dependences = OCMSet.new

    SECTIONS.each do |key, value|
      @require[key].each do |req|
        found = false

        list.each do |iface|
          if iface.provide[key].include?(req) then
            dependences[key] << iface
            found = true
          end
        end

        raise "#{@id.name}: no dependence found for #{req.name}." unless found
      end
    end

    return dependences.values.flatten.uniq
  end

  #
  # Resolve the interface's dependences graph.
  #

  def resolveDependences(list)
    # Filter interfaces in the interface_list conflicting with the
    # main interface if it is tagged unique
    # 

    if @unique then
      filtered_interfaces = list.find_all do |f|
        f != self && f.overlap?(self)
      end
      filtered_interfaces.each { |f| list.delete(f) }
    end

    #
    # Compute the dependencies and try to resolve the conflicts, if any.
    #

    dlist, rlist, xlist = self.resolveDependencesRecursive([], list, [], [])

    rlist.each do |r|
      overlap = []
      r_interface = list.find { |c| c.id == r }
      overlap = xlist.find_all { |x| x.overlap?(r_interface) }

      if not overlap.empty? then
        overlap.each { |o| xlist.delete(o) }
      end
    end

    if not xlist.empty? then
      error = "Conflict found: "
      xlist.each { |x| error += x.id.to_s + ' ' }
      abort error
    end

    return dlist
  end

  def resolveDependencesRecursive(rlist, clist, dlist, xlist)
    local_deps, final_deps = [], []
    injections = []
    dependences = self.computeDependences(clist)

    #
    # Inject the required interfaces
    #

    @ids["inject"].each do |i|
      inject = clist.find { |f| f.id == i }
      if inject == nil then
        print @id.to_s + ": "
        abort "cannot inject " + i.to_s + ", it does not exist."
      else
        dependences << inject
      end
    end

    local_deps = dependences.uniq

    #
    # Check if the interface's restrictions match existing interfaces
    #

   @ids["restrict"].each do |r|
      match = clist.find_all { |m| m.id == r }

      if match.empty? then
        puts "Error with restriction: " + r.to_s 
        abort "Cannot find a matching interface."
      end
    end

    #
    # Update the restrictions
    #

    rlist += @ids["restrict"]
    rlist.uniq!

    #
    # Check if their is no conflict in the local dependencies
    #

    resolved_deps = local_deps.clone

    local_deps.each do |d|
      overlap = []
      overlap = local_deps.find_all { |f| f != d and f.overlap?(d) }

      if not overlap.empty? and overlap.find { |o| o.unique } != nil then
        overlap << d
        filtered_overlap = overlap.clone

        rlist.each do |r|
          match = overlap.find { |o| r == o.id }
          if match != nil then
            filtered_overlap.delete(match)
          end
        end

        if filtered_overlap == overlap then
          xlist += filtered_overlap
        end

        filtered_overlap.each do |k|
          resolved_deps.delete(k)
        end
      end
    end

    #
    # Check of the local deps are already present in the global deps
    #

    filtered_deps = resolved_deps.clone

    resolved_deps.each do |l|
      match = dlist.find { |d| d == l }
      if match != nil then filtered_deps.delete(match) end
    end

    #
    # Parse through the dependencies, if necessary
    #

    if not filtered_deps.empty? then
      final_deps = (filtered_deps + dlist).uniq
      filtered_deps.each do |f|
        d, r, x = f.resolveDependencesRecursive(rlist, clist, final_deps, xlist)
        final_deps += d
        rlist += r
        xlist += x
      end
    end

    return final_deps.uniq, rlist.uniq, xlist.uniq
  end

  #
  # Check if two interfaces overlap.
  #

  def overlap?(c)
    union = @provide.merge(c.provide) { |k, o, n| (o + n).uniq }
    union.each do |key, value|
      length = @provide[key].length + c.provide[key].length
      return true if value.length < length
    end

    return false
  end

  #
  # Check if two interfaces are equal.
  #

  def eql?(i)
    return self.class == NilClass if i == nil
    return i.class == NilClass if self == nil
    return @id == i.id
  end

  #
  # Return the interface's hash value.
  #

  def hash
    return @id.hash
  end

  #
  # Display the interface in the terminal.
  #

  def display
    puts ("[" + @id.name + ", " + @id.version + "]").green.bold
    puts "author = ".blue + @author
    print "wrapper = ".blue + @wrapper.to_s
    puts ", unique = ".blue + @unique.to_s
    puts

    puts "[Path:]".green.bold
    puts @path

    ROLES.each do |role|
      puts "\n[#{role.capitalize}]".green.bold
      v = self.instance_variable_get(('@' + role).to_sym)
      SECTIONS.each { |key, value| v[key].each { |k| puts k } }
    end
  end

  private

  SECTIONS = { 'type' => OCMType, 'definition' => OCMDefinition,
        'variable' => OCMVariable, 'method' => OCMMethod }
  ROLES = [ 'provide', 'require' ]

  alias :== :eql?
end

