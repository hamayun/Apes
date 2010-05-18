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
require 'apes/object_file'

require 'rubygems'
require 'term/ansicolor'
require 'rake'

include Term::ANSIColor

class APECompilationUnit
  @@longer_name = ""
  attr_reader :objects, :update

  class CompilationError < RuntimeError
  end

  def initialize(component)
    @component = component
    @dependencies = []
    @objects = []
    @update = false

    if @component.id.name.length >= @@longer_name.length
      @@longer_name = @component.id.name
    end
  end

  def APECompilationUnit.createWith(component)
    # Check if the necessary env variables are present
    if ENV['APES_CC_FLAGS'] == nil
      raise CompilationError.new "Undefined APES_FLAGS variable."
    end

    if ENV['APES_CC_OPTIMIZATIONS'] == nil
      raise CompilationError.new "Undefined APES_OPTIMIZATIONS variable."
    end

    # If everything is OK, return an instance of the CcUnit
    APECompilationUnit.new(component)
  end

  def << (dependency)
    @dependencies << dependency
  end

  def updateObjectCache(cache)
    deps = @dependencies
    deps << (@component.path + '/Headers')
    deps << (@component.path + '/Headers/Public')

    csrcs = FileList[@component.path + '/Sources/*.c']
    asrcs = FileList[@component.path + '/Sources/*.S']

    (csrcs + asrcs).each do |file|
      object = APEObjectFile.createWith(file, @component, cache, deps)
      @update = @update || object.update
      @objects << object
    end
  end

  def build(mode)
    unless mode == :verbose
      print @component.id.name.blue
      (@@longer_name.length - @component.id.name.length + 1).times { print ' ' }

      print '|'.bold
      @objects.each { |object| print object.update ? ' '.on_cyan : ' '.on_green }
      print "|\e[#{@objects.length + 1}D".bold
    end

    # Compile the objects
    begin
      @objects.each { |o| o.build(mode) if o.update }
    rescue => e
      print "\r\e[2K" unless mode == :verbose
      raise e
    end

    print "\r\e[2K" unless mode == :verbose
  end

  def clean(mode)
    @objects.each do |o|
      puts o.to_s unless mode == :normal
      o.delete
    end
  end
end
