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

class APEObjectFile
  attr_reader :source, :update, :name, :cmd

  def APEObjectFile.create(name, buildir, source, deps)
    update = true
    has_modification = false
    object_path = buildir + '/' + name

    cmd_array = [ENV['TARGET_CC']]
    cmd_array << "-c -o #{buildir}/#{name}"
    cmd_array << ENV['TARGET_CFLAGS']
    cmd_array << deps.collect { |d| '-I' + d }.join(' ')
    cmd_array << source

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
          updated_files = FileList[dep + '/**/*.h'].find do |f| 
            file = File.new(f)
            dep_time = file.mtime
            file.close
            object_time < dep_time
          end 

          # If at least one of them is modified, we recompile
          if updated_files != nil then
            has_modification = true
            break
          end
        end 

        update = false if not has_modification
      end
    end

    APEObjectFile.new(name,source,update,cmd_array.join(' '))
  end

  private

  def initialize(name, source, update, cmd)
    @name = name
    @source = source
    @update = update
    @cmd = cmd
  end
end


