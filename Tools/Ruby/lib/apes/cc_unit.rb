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

  attr_reader :objects

  class CompilationError < RuntimeError
  end

  def initialize(name,path)
    @name = name
    @path = path
    @dependencies = []
    @objects = []
    @@longer_name = @name if @name.length >= @@longer_name.length
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
      base_name = (@name + ":" + file.split('/').last).ext('o')
      @objects << APEObjectFile.create(base_name, buildir, file, deps)
    end
  end

  def build(buildir, mode)

    unless mode == :verbose
      print @name.blue
      (@@longer_name.length - @name.length + 1).times { print ' ' }

      print '|'.bold
      @objects.each { |object| print object.update ? ' '.on_cyan : ' '.on_green }
      print "|\e[#{@objects.length + 1}D".bold
    end

    @objects.each do |o|
      if o.update then

        puts o.cmd unless mode == :normal

        pid, stdin, stdout, stderr = Open4::popen4(o.cmd)
        ignored, status = Process::waitpid2 pid 

        unless status == 0
          print "\r#{@name}".blue
          (@@longer_name.length - @name.length + 1).times { print ' ' }
          puts "(!!)".red
          raise CompilationError.new(stderr.readlines.join) 
        end

        print (mode == :normal) ? ' '.on_green : stdout.readlines.join
      else
        print "\e[C".on_green unless mode == :verbose
      end
    end

    print "\r\e[2K" unless mode == :verbose
  end
end
