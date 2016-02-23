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
  t = []
  Facter::Util::Resolution.exec("lsmod 2>/dev/null").each_line do |line|
    if not line =~ /.+/
      next
    end
    if line =~ /^Module.+/
      next
    end
    matches = line.match(/(\S+)/)
    if matches
      t.push(Thread.new {
        waitforit = []
        modulename = matches[1].strip
        retval[modulename] = {}

        if Facter::Util::Resolution.which('modinfo')
          waitforit.push(Thread.new {
            for info in modinfo
              retval[modulename][info] = Facter::Util::Resolution.exec("modinfo --field=#{info} #{modulename} 2>/dev/null").strip
            end
          })

          waitforit.push(Thread.new {
            retval[modulename]['parm'] = {}
            Facter::Util::Resolution.exec("grep '' /sys/module/#{modulename}/parameters/* 2>/dev/null").each_line do |txt|
              if not txt =~ /.+:.+/
                next
              end
              path = txt.split(':')[0]
              parm = path.split('/').last
              value = txt.split(':')[1].strip
              retval[modulename]['parm'][parm] = value
            end
            retval[modulename]['parm'].sort
          })

          #waitforit.push(Thread.new {
          #  retval[modulename]['alias'] = []
          #  Facter::Util::Resolution.exec("modinfo --field=alias #{modulename} 2>/dev/null").each_line do |txt|
          #    retval[modulename]['alias'].push(txt.strip)
          #  end
          #  retval[modulename]['alias'].sort
          #})

          waitforit.push(Thread.new {
            retval[modulename]['depends'] = []
            Facter::Util::Resolution.exec("modinfo --field=depends #{modulename} 2>/dev/null").each_line do |txt|
              retval[modulename]['depends']= txt.strip.split(',')
            end
            retval[modulename]['depends'].sort
          })
        end

        if Facter::Util::Resolution.which('rpm')
          waitforit.push(Thread.new {
              # this is really slow
              retval[modulename]['RPM'] = Facter::Util::Resolution.exec("rpm -qf #{retval[modulename]['filename']} 2>/dev/null").strip
          })
        end

        for thread in waitforit
          thread.join
        end
        retval[modulename].sort
      })
    end
    for thread in t
      thread.join
    end
  end

  Facter.add(:lsmod) do
    confine :kernel => "Linux"
    setcode do
      retval.sort
    end
  end
end
