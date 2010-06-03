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

require 'ocm/interface'

class APELibraryParser
  
  def APELibraryParser.getInterfaceList(mode = :normal)
    interface_path = []
    if @@interface_list.empty?

      if ENV[@@ENV_NAME] == nil or ENV[@@ENV_NAME].empty? then
        raise RuntimeError
      end

      interface_path = ENV[@@ENV_NAME].split ':'
      interface_path.uniq!

      interface_path.each do |path|
        APELibraryParser.parse(path, mode)
      end
    end

    return @@interface_list
  end

  def APELibraryParser.findInterfaceWith(id)
    APELibraryParser.getInterfaceList if @@interface_list.empty?
    interfaces = @@interface_list.find_all { |e| e.id == id }
    return interfaces
  end

  private

  @@interface_list = []
  @@ENV_NAME = 'APES_PATH'

  def APELibraryParser.parse(path, mode = :normal)
    begin
      if File.exist?(path + '/interface.xmi') then
        iface = OCMInterface.createFromXMLFileAtPath(path, mode)

        if iface != nil and not @@interface_list.entries.include?(iface)
          @@interface_list << iface
        end
      end

      Dir.new(path).entries.each do |e|
        if e != "." and e != ".." and e[0] != "." then
          dir = path + '/' + e
          APELibraryParser.parse(dir, mode) if FileTest.directory?(dir)
        end
      end
    rescue Errno::EACCES
      puts "[ACCESS ERROR] " + path
    end
  end
end
