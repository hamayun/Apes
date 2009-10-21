require 'term/ansicolor'
require 'open4'
require 'apes/cc_unit'

include Term::ANSIColor

class APELinkingUnit

  def APELinkingUnit.link(buildir,cc_units)
    objects = []
    cc_units.each { |cc| objects << cc.objects }


  end
end

