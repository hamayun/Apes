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

require 'apes/application'
require 'apes/parser'
require 'ocm/id'
require 'ocm/interface'

require 'rubygems'
require 'term/ansicolor'
include Term::ANSIColor

class APEInfoApplication < APEApplication

  def run(arguments = "")
    super(arguments)
    self.displayHelpAndExit unless @arguments.empty? or @arguments.count == 2

    begin
      interface_list = APELibraryParser.getInterfaceList(@verbose)

      case @arguments.count
      when 0 
        i = OCMInterface.createFromXMLFileAtPath(Dir.pwd, @verbose)
        raise Exception.new('No interface in this directory.') if i == nil
        interface_list << i if APELibraryParser.findInterfaceWith(i.id).empty?

      when 2
        id = OCMId.new(@arguments[0], nil, @arguments[1])
        interface = APELibraryParser.findInterfaceWith(id)
      end

      interface.display
      return 0

    rescue Exception => e
      puts e.message
      return -1
    end
  end

  def displayHelpAndExit
    puts "USAGE"
    puts "    apes-info {<name> <version>}"
    puts
    super
  end
end
