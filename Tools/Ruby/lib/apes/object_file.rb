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
require 'popen4'

class APEObjectFile
  attr_reader :update, :object

  class ObjectError < RuntimeError
  end

  def initialize(source, component, sandbox, includes)
    @source = source
    @component = component
    @includes = includes
    @sandbox = sandbox
    @object = sandbox + '/object'
    @description = sandbox + '/description'
  end

  def APEObjectFile.createWith(source, component, cache, includes)
    component_var = component.id.short_name.upcase + '_CC_FLAGS'

    # Compute the object hash
    signature = component.id.name + ':' + source + ':'
    signature += component.id.version + ':'
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
      description.puts('Component: ' + component.path)
      description.puts('File: ' + source)
      description.puts('Includes: ' + includes.join(' '))
      description.puts('Optimizations: ' + ENV['APES_CC_OPTIMIZATIONS'])

      unless ENV[component_var] == nil
        description.puts('Locals: ' + ENV[component_var])
      end
    end

    # Create the object file
    APEObjectFile.new(source, component, sandbox, includes)
  end

  def APEObjectFile.createFrom(sandbox)
    unless File.exist?(sandbox)
      raise ObjectError.new "Invalid sandbox path."
    end

    # Load the information
    description = File.new(sandbox + '/description')

    path = description.readline.chomp.split(' ')
    path.delete('Component:')
    path = path.join(' ')

    source = description.readline.chomp.split(' ')
    source.delete('File:')
    source = source.join(' ')

    includes = description.readline.chomp.split(' ')
    includes.delete('Includes:')

    # Create the object file
    component = APEComponent.createFromXMLFileAtPath(path)
    APEObjectFile.new(source, component, sandbox, includes)
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

  def build(mode)
    status = 0
    stdout = []
    stderr = []
    component_var = @component.id.short_name.upcase + '_CC_FLAGS'

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
    command = cmd_array.join(' ')

    # Display the command
    puts command unless mode == :normal

    if update then
      status = POpen4::popen4(command) do |out,err|
        stdout = out.readlines
        stderr = err.readlines
      end

      if status == nil
        message = "Cannot execute " + ENV['APES_COMPILER']
        message += ", no such file or directory"
        raise ObjectError.new message
      elsif status != 0
        raise ObjectError.new(stderr.join)
      end

      print (mode == :normal) ? ' '.on_green : stdout.join
    else
      print "\e[C".on_green unless mode == :verbose
    end

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
    id = @component.id.name + '(' + @component.id.version + ')'
    id += ':' + @source.split('/').last
    return id
  end
end
