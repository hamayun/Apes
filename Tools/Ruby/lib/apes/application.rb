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

class APEApplication

  def initialize(parser)
    @parser = parser
    @verbose = false
    @arguments = []
  end

  def self.new
    parser = OptionParser.new(:unknown_options_action => :raise) do |o|
      yield(o) if block_given?

      o << Option.new(:names => %w(--verbose -v),
                      :arg_arity => [ 0, 0 ],
                      :opt_description => "Enables verbose mode.")

      o << Option.new(:names => %w(--help -h),
                      :arg_arity => [ 0, 0 ],
                      :opt_description => "Displays this help.")
    end

    return super(parser)
  end

  def run(arguments)
    results = @parser.parse(arguments)
    @arguments = results.args
    self.displayHelpAndExit if results["--help"]
    @verbose = results["--verbose"]
    return 0
  end

  def displayHelpAndExit
    puts @parser.to_s
    exit 0
  end

end
