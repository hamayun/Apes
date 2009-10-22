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

require 'apes/component'

class APELibraryParser
  
  def APELibraryParser.getComponentList
    component_path = []
    component_list = []

    if ENV[@@ENV_NAME] == nil or ENV[@@ENV_NAME].empty? then
      raise RuntimeError
    end

    component_path = ENV[@@ENV_NAME].split ':'
    component_path << Dir.pwd
    component_path.uniq!

    component_path.each do |path|
      APELibraryParser.APEParsePath path, component_list
    end

    component_list
  end

  private

  @@ENV_NAME = 'APES_COMPONENT_PATH'

  def APELibraryParser.APEParsePath path, components_list
    directory = Dir.new(path)

    # First, check if the directory has a component.xml file

    if directory.entries.find { |e| e == "component.xml" } != nil then

      # Create a component object from the path
      cmp = APEComponent.createFromXMLFileAtPath path 

      if components_list.entries.find { |e| e.id == cmp.id } == nil
        components_list << cmp
      end
    else
      directory.entries.each do |e|
        if e != "." and e != ".." and e[0] != "." then
          new_path = path + '/' + e
          if FileTest.directory? new_path  then
            APELibraryParser.APEParsePath new_path, components_list 
          end
        end
      end
    end
  end
end
