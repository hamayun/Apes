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

require 'apes/cc_unit'

require 'rubygems'
require 'term/ansicolor'
require 'open4'

include Term::ANSIColor

class APELinkUnit

  class LinkError < RuntimeError
  end

  def APELinkUnit.link(name, buildir, cc_units, mode)

    # Check if the necessary env variables are present
    if ENV['TARGET_LD'] == nil
      raise CompilationError.new "Missing TARGET_LD environment variable."
    end

    if ENV['TARGET_LDFLAGS'] == nil
      raise CompilationError.new "Missing TARGET_LDFLAGS environment variable."
    end

    # We get the complete object list
    objects = []
    cc_units.each { |cc| objects += cc.objects }

    # We try to link the objects
    cmd = [ENV['TARGET_LD']]
    cmd << "-o #{name}"
    cmd << ENV['TARGET_LDFLAGS']
    objects.each { |o| cmd << "#{buildir}/#{o.sha1}" }

    puts cmd.join(' ')  unless mode == :normal

    begin
      pid, stdin, stdout, stderr = Open4::popen4(cmd.join(' '))
      ignored, status = Process::waitpid2 pid 
    rescue Errno::ENOENT => e
      message = "Cannot execute " + ENV['TARGET_LD']
      message += ", no such file or directory"
      raise LinkError.new message
    end

    if status != 0 then
      raise LinkError.new stderr.readlines.join
    end 

    print "\r\e[2K" if mode == :normal
  end
end

