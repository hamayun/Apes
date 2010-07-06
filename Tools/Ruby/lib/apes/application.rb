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

require 'rubygems'
require 'commandline/optionparser'
include CommandLine

class APEApplication < OptionParser

  def initialize(*arguments)
    super(*arguments)
    @arguments = []
  end

  def extendOptions
    self << Option.new(:names => %w(--verbose -v),
                       :arg_arity => [ 0, 0 ],
                       :opt_description => "Enables verbose mode.",
                       :opt_found => lambda { @verbose = true},
                       :opt_not_found => lambda { @verbose = false })

    self << Option.new(:names => %w(--help -h),
                       :arg_arity => [ 0, 0 ],
                       :opt_description => "Displays this help.",
                       :opt_found => lambda { @help = true },
                       :opt_not_found => lambda { @help = false })

  end

  def self.new
    parser = super(:unknown_options_action => :raise)
    parser.extendOptions
    return parser
  end

  def run(arguments)
    begin
      @arguments = self.parse(arguments).args
      self.displayHelpAndExit if @help
      return 0

    rescue Exception => e
      puts "\r\e[2K[#{e.class}]".red
      puts e.message
      puts e.backtrace if @verbose
      exit
    end
  end

  def displayHelpAndExit
    puts self.to_s
    exit 0
  end

end
