require 'term/ansicolor'
require 'open4'

include Term::ANSIColor

class APEObjectFile
  attr_accessor :build
  attr_reader :source

  def initialize(source)
    @source = source
    @build = true
  end
end

class APECompilationUnit
  @@longer_name = ""

  attr_reader :dependencies, :objects, :path

  def initialize(path)
    @path = path
    @name = path.split('/').last
    @dependencies = []
    @objects = {} 

    csrcs = FileList[@path + '/Sources/*.c']
    asrcs = FileList[@path + '/Sources/*.S']

    (csrcs + asrcs).each do |file|
      base_name = @name + ":" + file.split('/').last
      @objects[base_name.ext('o')] = APEObjectFile.new(file)
    end

    @@longer_name = @name if @name.length >= @@longer_name.length
  end

  def << (dependency)
    @dependencies << dependency
  end

  def updateObjectCache(buildir)
    @objects.each do |name,object|
      object_path = buildir + '/' + name
      
      if File.exist?(object_path) then 

        # Get the Modification Time of the object
        file = File.new(object_path)
        object_time = file.mtime
        file.close

        # Get the Modification Time of the source file
        file = File.new(object.source)
        source_time = file.mtime
        file.close

        if object_time <= source_time then
          needs_update = false
          global_dependencies = @dependencies
          global_dependencies << @path + '/Headers/Public'
          global_dependencies << @path + '/Headers/Private'

          global_dependencies.each do |dep|

            # Check each header file of the dependence
            updated_file = FileList[dep + '/*.h'].find do |f| 
              file = File.new(f)
              dep_time = file.mtime
              file.close
              object_time < dep_time
            end 

            # If at least one of them is modified, we recompile
            if updated_file != nil then
              needs_update = true
              break
            end 
          end 

          object.build = false unless needs_update
        end 
      end 
    end 
  end

  def build (mode)
    # We print the prologue
    print '[CC] '.green + @name.blue
    (@@longer_name.length - @name.length + 1).times { print ' ' }

    # Then the progress bar
    print '['.bold
    @objects.each { |k, object| print object.build ? '-' : '=' }
    print "]\e[#{@objects.length + 1}D".bold

    # Finally, we compile what needs to be compiled
    @objects.each do |name,object|
      if object.build then
        print ">\e[D"
        command = "#{ENV['TARGET_CC']} -c -o Build/#{name} #{ENV['TARGET_CFLAGS']}"
        @dependencies.collect { |d| '-I' + d }.each { |d| command += " #{d}" }
        command += " -I#{@path}/Headers -I#{@path}/Headers/Public"
        command += " #{object.source}"

        pid, stdin, stdout, stderr = Open4::popen4(command)
        ignored, status = Process::waitpid2 pid 

        if status != 0 then
          puts "\r\e[2K[!!] ".red + @name.blue
          puts
          puts "<Compiler report:>".red
          stderr.each do |line|
            puts line
          end 
          raise Exception.new 'Compilation failed.'
        end 

        print "=" 
      else
        print "\e[C"
      end
    end

    # And we print the epilogue
    puts "\r\e[2K[OK] ".green + @name.blue
  end
end

