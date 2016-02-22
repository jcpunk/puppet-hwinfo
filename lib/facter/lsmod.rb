#
# Fact: lsusb
#
# Purpose: get the results of lsusb
#
# Resolution:
#   Uses lsusb
#
# Caveats:
#   Needs lsusb in path
#
# Notes:
#   The result is 
#
if Facter::Util::Resolution.which('lsmod')
  retval = {}
  modinfo = ['filename', 'intree', 'srcversion', 'vermagic', 'version']
  Facter::Util::Resolution.exec("lsmod 2>/dev/null").each_line do |line|
    if not line =~ /.+/
      next
    end
    if line =~ /^Module.+/
      next
    end
    matches = line.match(/(\S+)/)
    if matches
      modulename = matches[1].strip
      retval[modulename] = {}
      if Facter::Util::Resolution.which('modinfo')
        for info in modinfo
          retval[modulename][info] = Facter::Util::Resolution.exec("modinfo --field=#{info} #{modulename} 2>/dev/null").strip
        end

        retval[modulename]['parm'] = []
        Facter::Util::Resolution.exec("modinfo --field=parm #{modulename} 2>/dev/null").each_line do |txt|
          retval[modulename]['parm'].push(txt.strip)
        end

        retval[modulename]['alias'] = []
        Facter::Util::Resolution.exec("modinfo --field=alias #{modulename} 2>/dev/null").each_line do |txt|
          retval[modulename]['alias'].push(txt.strip)
        end

        retval[modulename]['depends'] = []
        Facter::Util::Resolution.exec("modinfo --field=depends #{modulename} 2>/dev/null").each_line do |txt|
          retval[modulename]['depends']= txt.strip.split(',')
        end

        if Facter::Util::Resolution.which('rpm')
          retval[modulename]['RPM'] = Facter::Util::Resolution.exec("rpm -qf #{retval[modulename]['filename']} 2>/dev/null").strip
        end
      end
    end
  end

  Facter.add(:lsmod) do
    confine :kernel => "Linux"
    setcode do
      retval
    end
  end
end
