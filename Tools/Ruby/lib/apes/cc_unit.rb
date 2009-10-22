require 'term/ansicolor'
require 'open4'
require 'apes/object_file'

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

    # Compute dependency path
    deps = @dependencies
    deps << (@path + '/Headers/Public')
    deps << (@path + '/Headers/Private')

    # Build up the object cache
    csrcs = FileList[@path + '/Sources/*.c']
    asrcs = FileList[@path + '/Sources/*.S']

    (csrcs + asrcs).each do |file|
      base_name = (@name + ":" + file.split('/').last).ext('o')
      @objects << APEObjectFile.createFromObjectFile(base_name, buildir, file, deps)
    end
  end

  def build(buildir,mode)

    # We print the prologue
    print @name.blue
    (@@longer_name.length - @name.length + 1).times { print ' ' }
    print '(CC) '.green

    # Then the progress bar
    print '['.bold
    @objects.each { |object| print object.update ? '-' : '=' }
    print "]\e[#{@objects.length + 1}D".bold

    # Finally, we compile what needs to be compiled
    @objects.each do |object|
      if object.update then
        print ">\e[D"
        cmd = "#{ENV['TARGET_CC']} -c -o #{buildir}/#{object.name} #{ENV['TARGET_CFLAGS']} "
        cmd += @dependencies.collect { |d| '-I' + d }.join(' ')
        cmd += " -I#{@path}/Headers -I#{@path}/Headers/Public"
        cmd += " #{object.source}"

        pid, stdin, stdout, stderr = Open4::popen4(cmd)
        ignored, status = Process::waitpid2 pid 

        if status != 0 then
          print "\r\e[2K#{@name}".blue
          (@@longer_name.length - @name.length + 1).times { print ' ' }
          puts "(!!)".red
          raise CompilationError.new stderr.readlines.join
        end 

        print "=" 
      else
        print "\e[C"
      end
    end

    # And we print the epilogue
    print "\r\e[2K#{@name}".blue
    (@@longer_name.length - @name.length + 1).times { print ' ' }
    puts "(OK)".green
  end

end

