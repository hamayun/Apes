require 'apes/resolve'
require 'tmpdir'

def generate_sandbox(component, list, local)
  dependencies = []
  dependencies = component_resolve(component, list, [])

  if dependencies.empty? then
    abort "[genbox] No dependencies for: " + component.id.to_s
  end

  #
  # Make a temporary directory
  #

  if local then
    if FileTest.exist?("sandbox") then
      abort "[genbox] --here set, and the \"sandbox\" directory exists."
    else
      Dir.mkdir("sandbox")
      tmpdir = Dir.pwd + "/sandbox"
      puts "[genbox] " + tmpdir
    end
  else
    tmpdir = Dir.mktmpdir("apes-")
    puts "[genbox] " + tmpdir
  end

  #
  # Create the main makefile
  #

  makefile = File.open(tmpdir + "/Makefile", "w+")

  makefile.puts "SUBDIRS = "
  makefile.puts "OBJECTS = "
  makefile.puts

  dependencies.each do |d|
    if not d.wrapper then
      makefile.puts "SUBDIRS += " + d.id.name
      makefile.puts "OBJECTS += " + d.id.name + "/*.o"
      makefile.puts
    end
  end
  makefile.puts

  makefile.puts "default: build link"
  makefile.puts

  makefile.puts "build:"
  makefile.puts "\tfor i in $(SUBDIRS); \\"
  makefile.puts "\t\tdo echo '[CC] '$$i' \\c'; \\"
  makefile.puts "\t\tmake -C $$i default || exit $?; \\"
  makefile.puts "\t\techo '\r[OK] '$$i; \\"
  makefile.puts "\t\tdone;"
  makefile.puts

  makefile.puts "link:"
  makefile.puts "\techo -n '[LD] " + component.id.short_name + ".x [o]\e[2D'"
  makefile.print "\t$(TARGET_LD) $(TARGET_LDFLAGS) "
  makefile.print "-o $(PWD)/" + component.id.short_name + ".x "
  makefile.puts "$(OBJECTS) $(LDFLAGS)"
  makefile.puts "\techo '\e[2D\e[K\r[OK] " + component.id.short_name + ".x'"

  makefile.puts "clean:"
  makefile.puts "\tfor i in $(SUBDIRS); \\"
  makefile.puts "\t\tdo echo '[CLEAN] '$$i; \\"
  makefile.puts "\t\trm -f $$i/*.o ; \\"
  makefile.puts "\t\trm -f $(PWD)/" + component.id.short_name + ".x; \\"
  makefile.puts "\t\tdone;"
  makefile.puts
 
  makefile.close

  #
  # Populate the temporary directory
  #

  dependencies.each do |d|
    if not d.wrapper then
      Dir.mkdir(tmpdir + "/" + d.id.name)
      makefile = File.open(tmpdir + "/" + d.id.name + "/Makefile", "w+")

      makefile.puts "CFLAGS = $(TARGET_CFLAGS)"

      local_deps = component_resolve(d, dependencies, [])
      local_deps.each do |l|
        if l == d then
          makefile.puts "CFLAGS += -I" + d.path + "/Headers"
        end

        if not l.wrapper then
          makefile.puts "CFLAGS += -I" + l.path + "/Headers/Public"
        end
      end
      makefile.puts

      makefile.puts "SRCDIR = " + d.path + "/Sources"
      makefile.puts "CSRCS = $(wildcard $(SRCDIR)/*.c)" 
      makefile.puts "ASRCS = $(wildcard $(SRCDIR)/*.S)" 
      makefile.puts "OBJS = $(CSRCS:$(SRCDIR)/%.c=%.o)" 
      makefile.puts "OBJS += $(ASRCS:$(SRCDIR)/%.S=%.o)" 
      makefile.puts "NOBJS = $(shell echo $(OBJS) | wc -w | tr -d ' ')" 
      makefile.puts "NOBJSP = $(shell dc -e '$(NOBJS) 1 + p')" 
      makefile.puts

      makefile.puts "default: prefix $(OBJS) suffix"
      makefile.puts "ifneq (\"$(NOBJS)\", \"0\")"
      makefile.puts "\techo -n '\e['$(NOBJS)'D\e[K'"
      makefile.puts "endif"
      makefile.puts "\ttouch dummy.o"
      makefile.puts

      makefile.puts "prefix:"
      makefile.puts "ifneq (\"$(NOBJS)\",\"0\")"
      makefile.puts "\techo -n '['"
      makefile.puts "\tfor i in {1..$(NOBJS)} ; do echo '-\\c'; done"
      makefile.puts "\techo -n ']\e[$(NOBJSP)D'"
      makefile.puts "endif"
      makefile.puts

      makefile.puts "suffix:"
      makefile.puts "ifneq (\"$(NOBJS)\",\"0\")"
      makefile.puts "\techo -n '\e[$(NOBJSP)D\e[K'"
      makefile.puts "endif"

      makefile.puts "%.o : $(SRCDIR)/%.c"
      makefile.puts "\techo -n '>\e[D'"
      makefile.puts "\t$(TARGET_CC) -c -o $@ $(CFLAGS) $<"
      makefile.puts "\techo -n '='"
      makefile.puts

      makefile.puts "%.o : $(SRCDIR)/%.S"
      makefile.puts "\t$(TARGET_CC) -c -o $@ $(CFLAGS) $<"
      makefile.puts "\techo -n '='"
      makefile.puts

      makefile.close
    end
  end

  tmpdir
end

