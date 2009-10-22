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

require 'apes/resolve'

def generate_rakefile(component, list)
  dependencies = []
  dependencies = component_resolve(component, list, [])

  if dependencies.empty? then
    abort "[genbox] No dependencies for: " + component.id.to_s
  end

  #
  # Define the object dir name
  #

  tmpdir = Dir.pwd + "/.objects"

  #
  # Create the main rakefile
  #

  rakefile = File.open("Rakefile", "w+")

  rakefile.puts "#!/usr/bin/env ruby"
  rakefile.puts
  rakefile.puts "require 'rake/clean'"
  rakefile.puts "require 'apes/cc_unit'"
  rakefile.puts "require 'apes/ld_unit'"
  rakefile.puts
  rakefile.puts "#"
  rakefile.puts "# Check the environment"
  rakefile.puts "#"
  rakefile.puts
  rakefile.puts "if ENV['TARGET_CC'] == nil or ENV['TARGET_CC'].empty? then"
  rakefile.puts "  abort '[rake] No target CC defined.'"
  rakefile.puts "end"
  rakefile.puts
  rakefile.puts "if ENV['TARGET_CFLAGS'] == nil or ENV['TARGET_CFLAGS'].empty? then"
  rakefile.puts "  abort '[rake] No target CFLAGS defined.'"
  rakefile.puts "end"
  rakefile.puts
  rakefile.puts "if ENV['TARGET_LD'] == nil or ENV['TARGET_LD'].empty? then"
  rakefile.puts "  abort '[rake] No target LD defined.'"
  rakefile.puts "end"
  rakefile.puts
  rakefile.puts "if ENV['TARGET_LDFLAGS'] == nil or ENV['TARGET_LDFLAGS'].empty? then"
  rakefile.puts "  abort '[rake] No target LDFLAGS defined.'"
  rakefile.puts "end"
  rakefile.puts
  rakefile.puts "#"
  rakefile.puts "# Define the build parameters"
  rakefile.puts "#"
  rakefile.puts
  rakefile.puts "BUILD_DIR = '#{tmpdir}'"
  rakefile.puts "BINARY = '#{Dir.pwd}/#{component.id.short_name}'"
  rakefile.puts

  #
  # Create the compilation units
  #

  rakefile.puts "cc_unit = {}"

  dependencies.each do |d|
    if not d.wrapper then
      rakefile.puts "cc_unit['#{d.id.name}'] = APECompilationUnit.new '#{d.id.name}', '#{d.path}'"

      component_resolve(d, dependencies, []).each do |l|
        rakefile.puts "cc_unit['#{d.id.name}'] << '#{l.path}/Headers/Public'" unless l.wrapper
      end

      rakefile.puts
    end
  end

  rakefile.puts "#"
  rakefile.puts "# Extend the CLEAN constant"
  rakefile.puts "#"
  rakefile.puts
  rakefile.puts "CLEAN.include(BUILD_DIR)"
  rakefile.puts "CLEAN.include(BINARY)"
  rakefile.puts
  rakefile.puts "#"
  rakefile.puts "# Build the components"
  rakefile.puts "#"
  rakefile.puts
  rakefile.puts "task :default => [:build, :link]"
  rakefile.puts
  rakefile.puts "task :build do"
  rakefile.puts
  rakefile.puts "  # We create the objects directory"
  rakefile.puts "  if not File.exist?(BUILD_DIR) then"
  rakefile.puts "    Dir.mkdir(BUILD_DIR)"
  rakefile.puts "  end"
  rakefile.puts
  rakefile.puts "  # we scan the compilation units"
  rakefile.puts "  cc_unit.each do |key, unit|"
  rakefile.puts
  rakefile.puts "    # We update the objects cache"
  rakefile.puts "    unit.updateObjectCache(BUILD_DIR)"
  rakefile.puts
  rakefile.puts "    # We build the unit"
  rakefile.puts "    begin"
  rakefile.puts "      unit.build(BUILD_DIR, :normal)"
  rakefile.puts "    rescue APECompilationUnit::CompilationError => e"
  rakefile.puts "      puts"
  rakefile.puts "      puts '[Compilation error]'"
  rakefile.puts "      puts e.message"
  rakefile.puts "      exit"
  rakefile.puts "    rescue => e"
  rakefile.puts "      puts \"\r\e[2KRuby exception: \#{e.message}\""
  rakefile.puts "      exit"
  rakefile.puts "    end"
  rakefile.puts "  end"
  rakefile.puts "end"
  rakefile.puts
  rakefile.puts "task :link => [:build] do"
  rakefile.puts "  begin"
  rakefile.puts "    APELinkUnit.link(BINARY,BUILD_DIR,cc_unit)"
  rakefile.puts "  rescue APELinkUnit::LinkError => e"
  rakefile.puts "    puts"
  rakefile.puts "    puts '[Link error]'"
  rakefile.puts "    puts e.message"
  rakefile.puts "    exit"
  rakefile.puts "  rescue => e"
  rakefile.puts "    puts \"\r\e[2KRuby exception: \#{e.message}\""
  rakefile.puts "    exit"
  rakefile.puts "  end "
  rakefile.puts "end"
  rakefile.puts
end

