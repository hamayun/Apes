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

require 'apes/parse'

def component_depend(component, components_list)
  t_deps = []
  d_deps = []
  m_deps = []

  component.types["require"].each do |t|
    found = false

    components_list.each do |c|
      match = c.types["provide"].find { |i| i == t }

      if match != nil then
        found = true
        t_deps << c
      end
    end

    if not found then
      abort component.name + ": no dependence found for the type " + t.name
    end
  end


  component.defs["require"].each do |d|
    found = false

    components_list.each do |c|
      match = c.defs["provide"].find { |i| i == d }

      if match != nil then
        found = true
        d_deps << c
      end
    end

    if not found then
      abort component.name + ": no dependence found for the definition " + d.name
    end
  end

  component.methods["require"].each do |m|
    found = false

    components_list.each do |c|
      match = c.methods["provide"].find { |i| i == m }

      if match != nil then
        found = true
        m_deps << c
      end
    end

    if not found then
      abort component.id.name + ": no dependence found for the method " + m.name
    end
  end

  #
  # Check the managed methods
  #

  component.methods["manage"].each do |m|
    components_list.each do |c|
      match = c.methods["provide"].find { |i| i == m }

      if match != nil then
        m_deps << c
      end
    end
  end

  (t_deps + d_deps + m_deps).uniq
end


