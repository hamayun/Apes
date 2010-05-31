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

require 'apes/component'
require 'apes/id'
require 'apes/parse'

require 'rubygems'
require 'yaml'
require 'digest'
require 'popen4'

class APEObjectFile
  attr_reader :update, :object, :flags
  attr_reader :component, :version, :source

  class ObjectError < RuntimeError
  end

  def initialize(source, component, version, sandbox, includes, flags)
    @source = source
    @component = component
    @version = version
    @includes = includes
    @sandbox = sandbox
    @object = sandbox + '/object'
    @description = sandbox + '/description'
    @flags = flags
  end

  def APEObjectFile.createWith(source, component, cache, includes)
    component_var = component.id.short_name.upcase + '_CC_FLAGS'
    flags = ENV['APES_CC_OPTIMIZATIONS'] + ' ' +
      (ENV[component_var] != nil ? ENV[component_var] : "");

    #
    # Compute the object SHA1
    #

    signature = component.id.name + ':' + source + ':'
    signature += component.id.version + ':' + flags
    sha1 = Digest::SHA1.hexdigest signature
    sandbox = cache + '/' + sha1

    #
    # Generate the description file
    #
    
    if not File.exist?(sandbox) then 
      Dir.mkdir(sandbox)

      #
      # Compute the description hash
      #
      
      values = [ component.id.name, flags, includes.join(' '),
        source, component.id.version ]
      configuration = Hash[*@@config_keys.zip(values).flatten]

      #
      # Generate the YAML description file
      #

      File.open(sandbox + '/description', 'w+') do |f|
        YAML.dump(configuration, f)
      end
    elsif not File.directory?(sandbox)
      raise ObjectError.new "Invalid cache object: prune invalid objects."
    end

    #
    # Create the object file
    #

    APEObjectFile.new(source, component.id.name, component.id.version,
                      sandbox, includes, flags)
  end

  def APEObjectFile.createFrom(sandbox)
    object = nil

    if File.exist?(sandbox) and File.directory?(sandbox) then
      # Load the object's configuration file, check the keys
      # and create the object file
      #

      if File.exist?(sandbox + '/description') then
        config = File.open(sandbox + '/description', 'r') do |f|
          YAML.load(f)
        end

        if config.keys.sort == @@config_keys then
          object = APEObjectFile.new(config['source'], config['component'],
                                     config['version'], sandbox,
                                     config['includes'], config['flags'])
        end
      end
    end

    return object
  end

  def SHA1
    signature = @component + ':' + @source + ':'
    signature += @version + ':' + @flags
    return Digest::SHA1.hexdigest signature
  end

  def validate
    id = APEId.new(@component, nil, @version)
    components = APELibraryParser.findComponentWith(id)
    return (components != nil and not components.empty?)
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
          updated_files = Dir.glob(inc + '/**/*.h').find do |f| 
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

    # Build the command array
    cmd_array = [ENV['APES_COMPILER']]
    cmd_array << "-c -o #{@object}"
    cmd_array << ENV['APES_CC_FLAGS']
    cmd_array << @flags

    cmd_array << @includes.collect { |d| '-I' + d }.join(' ')
    cmd_array << @source
    command = cmd_array.join(' ')

    puts command unless mode == :normal

    # Execute the command
    if update then
      stdout, stderr = [], []
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

  private

  @@config_keys = [ "component", "flags", "includes", "source", "version" ]
end
