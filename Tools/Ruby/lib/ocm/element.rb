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

require 'term/ansicolor'
include Term::ANSIColor

class OCMElement
  attr :name, :visibility

  def initialize(name, visibility)
    @name = name
    @visibility = visibility
  end

  def OCMElement.createWith(name, visibility)
    e = nil
    if [:public, :private].include?(visibility) and name != nil
      e = OCMElement.new(name, visibility)
    end
    return e
  end

  def to_s
    v = @visibility.to_s
    v = @visibility == :private ? v.red : v.green
    return '[' + v + '] ' + @name.bold
  end

  def eql?(e)
    return self.class == NilClass if e == nil
    return e.class == NilClass if self == nil
    return @name == e.name && @visibility == e.visibility
  end

  def hash
    return [@name, @visibility].hash
  end

  alias :== :eql?
end

