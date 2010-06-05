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
  attr :path
  attr :provide
  attr :require
  attr :unique
  attr :wrapper

  #
  # Initialization method.
  #

  def initialize(path, id, author, unique, wrapper)
    @author = author
    @id = id
    @path = path
    @unique = unique
    @wrapper = wrapper

    @ids = { 'inject' => [], 'restrict' => [] }
    @provide = OCMSet.new
    @require = OCMSet.new
  end

  #
  # Class method to instantiate an interface
  # from a Nokogir NodeSet.
  #

  def OCMInterface.createFromXMLFileAtPath(path, verbose)

    #
    # Open and validate the XML using the interface schema
    #

    begin
      return nil unless File.exist?(path + '/interface.xmi')

      xml = Nokogiri.XML(File.open(path + '/interface.xmi'))
      xsd = Nokogiri::XML::Schema(File.open(SCHEMA_PATH))
      errors = xsd.validate(xml)

      if not errors.empty? then
        if verbose then
          puts "[SYNTAX ERROR]".red + " #{path}"
          errors.each { |e| puts e.message }
        end
        return nil
      end
    rescue Errno::ENOENT
      puts "[WARNING]".red + " The interface schema file cannot be found."
    end

    #
    # Get the top-level attributes
    #

    author = xml.root["author"]
    unique = xml.root["unique"] == "true"
    wrapper = xml.root["wrapper"] == "true"

    #
    # Get the interface's ID
    #

    id = OCMId.createFromXML(xml.xpath("/APES:Interface/id").first)
    iface = OCMInterface.new(path, id, author, unique, wrapper)

    #
    # Get the injected IDs
    #

    xml.xpath("/APES:Interface/inject/id").each do |node|
      id = OCMId.createFromXML(node)
      iface.ids['inject'] << id unless iface.ids['inject'].include?(id)
    end

    #
    # Get the restricted IDs
    #

    xml.xpath("/APES:Interface/restrict/id").each do |node|
      id = OCMId.createFromXML(node)
      iface.ids['restrict'] << id unless iface.ids['restrict'].include?(id)
    end

    #
    # Get the different items
    #

    ROLES.each do |role|
      OCMSet::SECTIONS.each do |section|
        xpath = "/APES:Interface/#{role}//#{section}"
        xml.xpath(xpath).each do |node|
          c = Kernel.const_get('OCM' + section.capitalize)
          t = c.createFromXML(node)
          v = iface.instance_variable_get(('@' + role).to_sym)
          v[section] << t unless v[section].include?(t) 
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

    OCMSet::SECTIONS.each do |section|
      @require[section].each do |req|
        found = false

        list.each do |iface|
          if iface.provide[section].include?(req) then
            dependences[section] << iface
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

    #
    # Resolve potential conflict if interface is unique.
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

    dlist = [ self ]
    dlist, rlist, xlist = self.resolveDependencesRecursive([], list, dlist, [])

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
      raise Exception.new(error)
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
        raise Exception.new("cannot inject " + i.to_s + ", it does not exist.")
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
        raise Exception.new("Cannot find a matching interface.")
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

    final_deps = (filtered_deps + dlist).uniq

    filtered_deps.each do |f|
      d, r, x = f.resolveDependencesRecursive(rlist, clist, final_deps, xlist)
      final_deps += d
      rlist += r
      xlist += x
    end unless filtered_deps.empty?

    return final_deps.uniq, rlist.uniq, xlist.uniq
  end

  #
  # Check if two interfaces are equal.
  #

  def overlap?(interface)
    return @provide.overlap?(interface.provide)
  end

  #
  # Check if two interfaces are equal.
  #

  def eql?(i)
    return false if i == nil
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
      OCMSet::SECTIONS.each { |key, value| v[key].each { |k| puts k } }
    end
  end

  private

  ROLES = [ 'provide', 'require' ]
  SCHEMA_PATH = ENV['APES_ROOT'] + '/Tools/Schemas/APESInterface.xsd'

  alias :== :eql?
end

