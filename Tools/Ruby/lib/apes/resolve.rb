require 'apes/parse'

def component_resolve_r(component, components_list, deps)
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
      abort component.id.name + ": no dependence found for the type " + t.name
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
      abort component.id.name + ": no dependence found for the definition " + d.name
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
      abort component.id.name + ": no dependence found for the method " + m.name
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
  # Parse through the dependencies, if necessary
  #

  if not local_deps.empty? then
    final_deps = (local_deps + deps).uniq
    local_deps.each do |f|
      final_deps += component_resolve_r(f, components_list, final_deps)
    end
  end

  final_deps.uniq
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
  # Compute the dependencies
  #

  dependencies = []
  dependencies << component

  dependencies += component_resolve_r(component, components_list, deps)
  dependencies.uniq!

  #
  # Get all the restriction lists
  #

  restrict = []
  restrict << component.id

  dependencies.each { |d| restrict += d.restricted_ids }
  restrict.uniq!

  #
  # Try to resolve the restriction
  #

  resolved_dependencies = dependencies.clone

  dependencies.each do |d|
    overlap = []
    overlap = dependencies.find_all { |f| f.overlap?(d) }

    if not overlap.empty? and overlap.find { |o| o.unique } != nil then
      overlap << d
      resolved_overlap = overlap.clone

      restrict.each do |r|
        match = resolved_overlap.find { |o| r == o.id }
        if match != nil then
          resolved_overlap.delete(match)
        end
      end

      resolved_overlap.each { |o| overlap.delete(o) }

      if overlap.empty? then
        puts "Conflict found for " + d.id.to_s + ":"
        resolved_overlap.each { |k| print k.id.to_s + " " }
        abort "\nAt least one of the components is tagged unique."
      end

      if overlap.length >= 2 then
        print "Conflicting restrictions: "
        overlap.each { |k| print k.id.to_s + " " }
        abort "\n"
      end

      resolved_overlap.each do |k|
        k.restricted_ids.each { |i| restrict.delete(i) }
        resolved_dependencies.delete(k)
      end
    end
  end

  #
  # Check if all the restrictions are met
  #

  resolved_dependencies.each do |d|
    d.restricted_ids.each do |r|
      match = resolved_dependencies.find { |d| d.id == r }
      if match == nil then
        puts "Unmatched restriction " + r.to_s + " for component " + d.id.to_s
        abort "The component either doesn't exist or need to be injected."
      end
    end
  end

  resolved_dependencies
end

