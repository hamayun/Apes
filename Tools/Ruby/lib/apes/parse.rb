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
