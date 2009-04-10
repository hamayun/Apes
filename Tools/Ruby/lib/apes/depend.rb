require 'apes/parse'

def component_depend(component, components_list)
  t_deps = []
  d_deps = []
  m_deps = []

  component.required_types.each do |t|
    found = false

    components_list.each do |c|
      match = c.provided_types.find { |i| i == t }

      if match != nil then
        found = true
        t_deps << c
      end
    end

    if not found then
      abort component.name + ": no dependence found for the type " + t.name
    end
  end


  component.required_definitions.each do |d|
    found = false

    components_list.each do |c|
      match = c.provided_definitions.find { |i| i == d }

      if match != nil then
        found = true
        d_deps << c
      end
    end

    if not found then
      abort component.name + ": no dependence found for the definition " + d.name
    end
  end

  component.required_methods.each do |m|
    found = false

    components_list.each do |c|
      match = c.provided_methods.find { |i| i == m }

      if match != nil then
        found = true
        m_deps << c
      end
    end

    if not found then
      abort component.name + ": no dependence found for the method " + m.name
    end
  end

  #
  # Check the managed methods
  #

  component.managed_methods.each do |m|
    components_list.each do |c|
      match = c.provided_methods.find { |i| i == m }

      if match != nil then
        m_deps << c
      end
    end
  end

  (t_deps + d_deps + m_deps).uniq
end


