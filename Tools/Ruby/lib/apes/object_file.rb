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

require 'rubygems'
require 'digest'

class APEObjectFile
  attr_reader :update, :object

  class ObjectError < RuntimeError
  end

  def initialize(source, component, version, sandbox, includes)
    @source = source
    @component = component
    @version = version
    @includes = includes
    @sandbox = sandbox
    @object = sandbox + '/object'
    @description = sandbox + '/description'
  end

  def APEObjectFile.createWith(source, component, version, cache, includes)
    component_var = component.upcase + '_CC_FLAGS'

    if ENV['APES_CC_FLAGS'] == nil
      raise ObjectError.new "Undefined APES_FLAGS variable."
    end

    if ENV['APES_CC_OPTIMIZATIONS'] == nil
      raise ObjectError.new "Undefined APES_OPTIMIZATIONS variable."
    end

    # Compute the object hash
    signature = source + ':' + version + ':'
    signature += ENV['APES_CC_FLAGS'] + ':'
    signature += ENV['APES_CC_OPTIMIZATIONS'] + ':'

    unless ENV[component_var] == nil
      signature += ENV[component_var]
    end

    sha1 = Digest::SHA1.hexdigest signature
    sandbox = cache + '/' + sha1

    # Check if the object directory exists
    if not File.exist?(sandbox) then 
      Dir.mkdir(sandbox)
      description = File.new(sandbox + '/description', 'w+')
      description.puts('File: ' + source)
      description.puts('Component: ' + component)
      description.puts('Version: ' + version)
      description.puts('Includes: ' + includes.join(' '))
      description.puts('Optimizations: ' + ENV['APES_CC_OPTIMIZATIONS'])

      unless ENV[component_var] == nil
        description.puts('Locals: ' + ENV[component_var])
      end
    end

    # Create the object file
    APEObjectFile.new(source, component, version, sandbox, includes)
  end

  def APEObjectFile.createFrom(sandbox)
    unless File.exist?(sandbox)
      raise ObjectError.new "Invalid sandbox path."
    end

    # Load the information
    description = File.new(sandbox + '/description')
    source = description.readline.chomp.split(' ')
    source.delete('File:')
    source = source.join(' ')
    puts source

    component = description.readline.chomp.split(' ')
    component.delete('Component:')
    component = component.join(' ')
    puts component

    version = description.readline.chomp.split(' ')
    version.delete('Version:')
    version = version.join(' ')
    puts version

    includes = description.readline.chomp.split(' ')
    includes.delete('Includes:')
    puts includes
    description.close

    # Create the object file
    APEObjectFile.new(source, component, version, sandbox, includes)
  end

  def update
    update = true
    has_modification = false

    # Check if the object has to be built
    if File.exist?(@object) then 
      # Get the Modification Time of the object
      file = File.new(@object)
      object_time = file.mtime
      file.close

      # Get the Modification Time of the source file
      file = File.new(@source)
      source_time = file.mtime
      file.close

      # Check if an update is needed
      if object_time > source_time then
        @includes.each do |inc|

          # Check each header file of the dependence
          updated_files = FileList[inc + '/**/*.h'].find do |f| 
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

    return update
  end

  def command
    component_var = @component.upcase + '_CC_FLAGS'

    # Build the command array
    cmd_array = [ENV['APES_COMPILER']]
    cmd_array << "-c -o #{@object}"
    cmd_array << ENV['APES_CC_FLAGS']
    cmd_array << ENV['APES_CC_OPTIMIZATIONS']

    unless ENV[component_var] == nil
      cmd_array << ENV[component_var]
    end

    cmd_array << @includes.collect { |d| '-I' + d }.join(' ')
    cmd_array << @source

    # Return the command value
    return cmd_array.join (' ')
  end

  def delete
    if File.exist? @object then
      File.delete @object
    end

    if File.exist? @description then
      File.delete @description
    end

    Dir.delete @sandbox
  end

  def identifier
    return @component + '(' + @version + '):' + @source.split('/').last
  end
end
