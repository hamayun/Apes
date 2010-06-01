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

require 'ocm/parse'
require 'ocm/depend'

#
# component_resolve_r arguments:
# * rlist = list of restrictions
# * clist = list of components
# * dlist = list of dependencies
# * xlist = list of conflicts
#

def component_resolve_r(component, rlist, clist, dlist, xlist)
  local_deps, final_deps = [], []
  dependences, injections = [], []

  #
  # Check the direct dependencies
  #

  dependences = component_depend(component, clist)

  #
  # Inject the required components
  #

  component.ids["inject"].each do |i|
    inject = clist.find { |f| f.id == i }
    if inject == nil then
      print component.id.to_s + ": "
      abort "cannot inject " + i.to_s + ", it does not exist."
    else
      dependences << inject
    end
  end

  #
  # Compute the local dependencies
  #

  local_deps = dependences.uniq

  #
  # Check if the component's restrictions match existing components
  #
  
  component.ids["restrict"].each do |r|
    match = clist.find_all { |m| m.id == r }

    if match.empty? then
      puts "Error with restriction: " + r.to_s 
      abort "Cannot find a matching component."
    end
  end

  #
  # Update the restrictions
  #
  
  rlist += component.ids["restrict"]
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
        # puts "Conflict found:"
        # filtered_overlap.each { |o| print o.id.to_s + ' ' }
        # puts "\nAt least one of the components is tagged unique."
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
      d, r, x = component_resolve_r(f, rlist, clist, final_deps, xlist)
      final_deps += d
      rlist += r
      xlist += x
    end
  end

  return final_deps.uniq, rlist.uniq, xlist.uniq
end

def component_resolve(component, clist)

  #
  # Filter components in the component_list conflicting with the
  # main component if it is tagged unique
  # 

  if component.unique then
    filtered_components = clist.find_all do |f|
      f != component && f.overlap?(component)
    end
    filtered_components.each { |f| clist.delete(f) }
  end

  #
  # Compute the dependencies
  #

  dlist, rlist, xlist = component_resolve_r(component, [], clist, [], [])

  #
  # Try to resolve the conflicts, if any.
  #
  
  rlist.each do |r|
    overlap = []
    r_component = clist.find { |c| c.id == r }
    overlap = xlist.find_all { |x| x.overlap?(r_component) }

    if not overlap.empty? then
      overlap.each { |o| xlist.delete(o) }
      # dlist << r_component
    end
  end

  if not xlist.empty? then
    puts "Conflict found:"
    xlist.each { |x| print x.id.to_s + ' ' }
    abort "\nTry to restrict the graph to one of them."
  end

  return dlist
end

