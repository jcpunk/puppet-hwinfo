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
  retval = []
  Facter::Util::Resolution.exec("lsmod 2>/dev/null").each_line do |line|
    if not line =~ /.+/
      next
    end
    if line =~ /^Module.+/
      next
    end
    matches = line.match(/(\S+)/)
    if matches
      retval.push(matches[1])
    end
  end

  Facter.add(:lsmod) do
    confine :kernel => "Linux"
    setcode do
      retval.sort
    end
  end
end
