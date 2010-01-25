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

def component_resolve_r(component, restrictions, components_list, deps)
  local_deps = []
  final_deps = []
  t_deps = []
  d_deps = []
  m_deps = []
  i_deps = []

  #
  # Check the required types
  #

  component.required_types.each do |t|
    found = false

    components_list.each do |c|
      match = c.provided_types.find { |i| i == t }

      if match != nil then
        found = true
        if deps.find { |i| i == c } == nil then t_deps << c end
      end
    end

    if not found then
      puts component.id.name + ": unresolved type " + t.name
      deps.delete component
      return []
    end
  end

  #
  # Check the required definitions
  #

  component.required_definitions.each do |d|
    found = false

    components_list.each do |c|
      match = c.provided_definitions.find { |i| i == d }

      if match != nil then
        found = true
        if deps.find { |i| i == c } == nil then d_deps << c end
      end
    end

    if not found then
      puts component.id.name + ": unresolved definition " + d.name
      deps.delete component
      return []
    end
  end

  #
  # Check the required methods
  #

  component.required_methods.each do |m|
    found = false

    components_list.each do |c|
      match = c.provided_methods.find { |i| i == m }

      if match != nil then
        found = true
        if deps.find { |i| i == c } == nil then m_deps << c end
      end
    end

    if not found then
      puts component.id.name + ": unresolved method " + m.name
      deps.delete component
      return []
    end
  end

  #
  # Inject the required components
  #

  component.injected_ids.each do |i|
    inject = components_list.find { |f| f.id == i }
    if inject == nil then
      print component.id.to_s + ": "
      abort "cannot inject " + i.to_s + ", it does not exist."
    else
      i_deps << inject
    end
  end

  #
  # Compute the local dependencies
  #

  local_deps = (t_deps + d_deps + m_deps + i_deps).uniq

  #
  # Check if the component's restrictions match existing components
  #
  
  component.restricted_ids.each do |r|
    match = components_list.find_all { |m| m.id == r }

    if match.empty? then
      puts "Error with restriction: " + r.to_s 
      abort "Cannot find a matching component."
    end
  end

  #
  # Update the restrictions
  #
  
  restrictions += component.restricted_ids
  restrictions.uniq!

  #
  # Check if their is no conflict in the local dependencies
  #
  
  local_deps.each do |d|
    overlap = []
    overlap = local_deps.find_all { |f| f.overlap?(d) }

    if not overlap.empty? and overlap.find { |o| o.unique } != nil then
      overlap << d

      restrictions.each do |r|
        match = overlap.find { |o| r == o.id }
        if match != nil then
          overlap.delete(match)
        end
      end

      overlap.each do |k|
        local_deps.delete(k)
      end
    end
  end

  #
  # Parse through the dependencies, if necessary
  #

  if not local_deps.empty? then
    final_deps = (local_deps + deps).uniq
    local_deps.each do |f|
      d, r = component_resolve_r(f, restrictions, components_list, final_deps)
      final_deps += d
      restrictions += r
    end
  end

  return final_deps.uniq, restrictions.uniq
end

def component_resolve(component, components_list, deps)

  #
  # Filter components in the component_list conflicting with the
  # main component if it is tagged unique
  # 

  if component.unique then
    filtered_components = components_list.find_all { |f| f.overlap?(component) }
    filtered_components.each { |f| components_list.delete(f) }
  end

  #
  # Build the restriction list
  #

  restrict = []
  restrict << component.id

  #
  # Compute the dependencies
  #

  dependencies = []
  dependencies << component

  d, r = component_resolve_r(component, restrict, components_list, deps)
  dependencies += d
  restrict += r
  dependencies.uniq!
  restrict.uniq!

  #
  # Try to resolve the restriction
  #

  dependencies.each do |d|
    overlap = []
    overlap = dependencies.find_all { |f| f.overlap?(d) }

    if not overlap.empty? and overlap.find { |o| o.unique } != nil then
      overlap << d

      restrict.each do |r|
        match = overlap.find { |o| r == o.id }
        if match != nil then
          overlap.delete(match)
        end
      end

      if overlap.empty? then
        puts "Conflict found for " + d.id.to_s + ":"
        overlap.each { |k| print k.id.to_s + " " }
        abort "\nAt least one of the components is tagged unique."
      end

      if overlap.length >= 2 then
        print "Conflicting restrictions: "
        overlap.each { |k| print k.id.to_s + " " }
        abort "\n"
      end

      overlap.each do |k|
        k.restricted_ids.each { |i| restrict.delete(i) }
        dependencies.delete(k)
      end
    end
  end

  #
  # Check if all the restrictions are met
  #

  dependencies.each do |d|
    d.restricted_ids.each do |r|
      match = dependencies.find { |d| d.id == r }
      if match == nil then
        puts "Unmatched restriction " + r.to_s + " for component " + d.id.to_s
        abort "The component either doesn't exist or need to be injected."
      end
    end
  end

  #
  # Retry the resolution in order to make sure
  # that we have the right component set
  #

  final_set = []
  final_set, r = component_resolve_r(component, restrict, dependencies, deps)

  #
  # If the previous operation did not abort,
  # then we have the right set :)
  #

  return final_set
end

