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
  tmphash = {}
  finalhash = {}
  modinfo = ['intree', 'srcversion', 'vermagic', 'version']
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

        tmphash[modulename] = {}

        if Facter::Util::Resolution.which('modinfo')
          # Can't do this in parallel, other things need it first
          for info in modinfo
            result = Facter::Util::Resolution.exec("modinfo --field='filename' #{modulename} 2>/dev/null").strip
            if not result.empty?
              tmphash[modulename]['filename'] = result
            end
          end
        end

        if Facter::Util::Resolution.which('modinfo')
          waitforit.push(Thread.new {
            for info in modinfo
              result = Facter::Util::Resolution.exec("modinfo --field=#{info} #{modulename} 2>/dev/null").strip
              if not result.empty?
                tmphash[modulename][info] = result
              end
            end
          })

          waitforit.push(Thread.new {
            if File.directory?("/sys/module/#{modulename}/parameters")
              tmphash[modulename]['parm'] = {}
              Facter::Util::Resolution.exec("grep '' /sys/module/#{modulename}/parameters/* 2>/dev/null").each_line do |txt|
                if not txt =~ /.+:.+/
                  next
                end
                path = txt.split(':')[0]
                parm = path.split('/').last
                value = txt.split(':')[1].strip
                tmphash[modulename]['parm'][parm] = value
              end
              tmphash[modulename]['parm'].sort
            end
          })

          waitforit.push(Thread.new {
            mytaint = Facter::Util::Resolution.exec("cat /sys/module/#{modulename}/taint 2>/dev/null")
            if not mytaint.empty?
              if mytaint != 'Y'
                tmphash[modulename]['taint'] = mytaint.strip
              end
            end
          })

          waitforit.push(Thread.new {
            tmphash[modulename]['depends'] = []
            Facter::Util::Resolution.exec("modinfo --field=depends #{modulename} 2>/dev/null").each_line do |txt|
              tmphash[modulename]['depends']= txt.strip.split(',')
            end
            if tmphash[modulename]['depends'] == []
              tmphash[modulename].delete('depends')
            else
              tmphash[modulename]['depends'].sort
            end
          })
        end

        if Facter::Util::Resolution.which('rpm')
          waitforit.push(Thread.new {
              realname = Facter::Util::Resolution.exec("readlink -f #{tmphash[modulename]['filename']} 2>/dev/null").strip
              # this is really slow
              if not realname.empty?
                tmphash[modulename]['package'] = Facter::Util::Resolution.exec("rpm -qf #{realname} 2>/dev/null").strip
              else
                tmphash[modulename]['package'] = Facter::Util::Resolution.exec("rpm -qf #{tmphash[modulename]['filename']} 2>/dev/null").strip
              end
          })
        elsif Facter::Util::Resolution.which('dpkg')
          waitforit.push(Thread.new {
              realname = Facter::Util::Resolution.exec("readlink -f #{tmphash[modulename]['filename']} 2>/dev/null").strip
              # this is really slow
              if not realname.empty?
                mypkgname = Facter::Util::Resolution.exec("dpkg -s #{realname} 2>/dev/null").strip
                tmphash[modulename]['package'] = mypkgname.split(':')[0]
              else
                mypkgname = Facter::Util::Resolution.exec("dpkg -s #{tmphash[modulename]['filename']} 2>/dev/null").strip
                tmphash[modulename]['package'] = mypkgname.split(':')[0]
              end
          })
        end

        for thread in waitforit
          thread.join
        end
        tmphash[modulename].sort
      })
    end
    for thread in t
      thread.join
    end
    finalhash = Hash[tmphash.sort]
  end

  Facter.add(:lsmod) do
    confine :kernel => "Linux"
    setcode do
      finalhash
    end
  end
end
