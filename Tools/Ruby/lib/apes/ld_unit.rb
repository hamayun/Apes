require 'term/ansicolor'
require 'open4'
require 'apes/cc_unit'

include Term::ANSIColor

class APELinkUnit

  class LinkError < RuntimeError
  end

  def APELinkUnit.link(name,buildir,cc_units)

    # We get the complete object list
    objects = []
    cc_units.each { |n, cc| objects += cc.objects }

    # We try to link the objects
    cmd = "#{ENV['TARGET_LD']} -o #{name} #{ENV['TARGET_LDFLAGS']} "
    objects.each { |o| cmd += " #{buildir}/#{o.name}" }

    pid, stdin, stdout, stderr = Open4::popen4(cmd)
    ignored, status = Process::waitpid2 pid 

    if status != 0 then
      puts "=> ".bold + "#{name}".red
      raise LinkError.new stderr.readlines.join
    end 

    # And we print the epilogue
    puts "=> ".bold + "#{name}".green
  end
end

