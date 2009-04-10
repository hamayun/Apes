require 'apes/component'

def APEParseLibrary(path, components_list)
  directory = Dir.new(path)

  # First, check if the directory has a component.xml file

  if directory.entries.find { |e| e == "component.xml" } != nil then

    # Create a component object from the path
    cmp = APEComponent.new(path)

    if components_list.entries.find { |e| e.id == cmp.id } == nil
      components_list << cmp
    end
  else
    directory.entries.each do |e|
      if e != "." and e != ".." and e[0] != "." then
        new_path = path + '/' + e
        if FileTest.directory?(new_path) then
          APEParseLibrary(new_path, components_list)
        end
      end
    end
  end
end

