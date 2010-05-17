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

require 'apes/object_file'

require 'rubygems'
require 'term/ansicolor'
require 'open4'
require 'rake'

include Term::ANSIColor

class APECompilationUnit
  @@longer_name = ""
  attr_reader :objects, :update

  class CompilationError < RuntimeError
  end

  def initialize(name,version,path)
    @name = name
    @version = version
    @path = path
    @dependencies = []
    @objects = []
    @update = false
    @@longer_name = @name if @name.length >= @@longer_name.length
  end

  def APECompilationUnit.createWith(name,version,path)
    # Check if the necessary env variables are present
    if ENV['TARGET_CC'] == nil
      raise CompilationError.new "Missing TARGET_CC environment variable."
    end

    if ENV['TARGET_CFLAGS'] == nil
      raise CompilationError.new "Missing TARGET_CFLAGS environment variable."
    end

    # If everything is OK, return an instance of the CcUnit
    APECompilationUnit.new(name, version, path)
  end

  def << (dependency)
    @dependencies << dependency
  end

  def updateObjectCache(buildir)
    deps = @dependencies
    deps << (@path + '/Headers')
    deps << (@path + '/Headers/Public')

    csrcs = FileList[@path + '/Sources/*.c']
    asrcs = FileList[@path + '/Sources/*.S']

    (csrcs + asrcs).each do |file|
      begin
        object = APEObjectFile.createWith(file, @name, @version, buildir, deps)
        @update = @update || object.update
        @objects << object
      rescue APEObjectFile::ObjectError => e
        raise CompilationError.new e.message
      end
    end
  end

  def build(buildir, mode)
    # Display the prologue
    unless mode == :verbose
      print @name.blue
      (@@longer_name.length - @name.length + 1).times { print ' ' }

      print '|'.bold
      @objects.each { |object| print object.update ? ' '.on_cyan : ' '.on_green }
      print "|\e[#{@objects.length + 1}D".bold
    end

    # Compile the objects
    @objects.each do |o|
      if o.update then

        puts o.cmd unless mode == :normal

        begin
          pid, stdin, stdout, stderr = Open4::popen4(o.command)
          ignored, status = Process::waitpid2 pid 
        rescue Errno::ENOENT => e
          message = "Cannot execute " + ENV['TARGET_CC']
          message += ", no such file or directory"
          raise CompilationError.new message
        end

        raise CompilationError.new(stderr.readlines.join) unless status == 0

        print (mode == :normal) ? ' '.on_green : stdout.readlines.join
      else
        print "\e[C".on_green unless mode == :verbose
      end
    end

    print "\r\e[2K" unless mode == :verbose
  end

  def clean(buildir, mode)
    @objects.each do |o|
      begin
        o.delete
        name = o.identifier.green
      rescue Errno::ENOENT 
        name = o.identifier.red
      end

      puts ["deleted".blue, name].join(' ') if mode == :verbose
    end
  end
end
