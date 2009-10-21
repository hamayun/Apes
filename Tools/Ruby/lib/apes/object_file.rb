class APEObjectFile
  attr_reader :source, :update, :name

  def APEObjectFile.createFromObjectFile(name, buildir, source, deps)
    update = true
    has_modification = false
    object_path = buildir + '/' + name

    if File.exist?(object_path) then 

      # Get the Modification Time of the object
      file = File.new(object_path)
      object_time = file.mtime
      file.close

      # Get the Modification Time of the source file
      file = File.new(source)
      source_time = file.mtime
      file.close

      # Check if an update is needed
      if object_time > source_time then
        deps.each do |dep|

          # Check each header file of the dependence
          updated_files = FileList[dep + '/**/*.h'].select do |f| 
            file = File.new(f)
            dep_time = file.mtime
            file.close
            object_time < dep_time
          end 

          # If at least one of them is modified, we recompile
          if not updated_files.empty? then
            has_modification = true
            break
          end
        end 

        update = false if not has_modification
      end
    end

    APEObjectFile.new(name,source,update)
  end

  private

  def initialize(name, source, update)
    @name = name
    @source = source
    @update = update
  end
end


