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
if Facter::Util::Resolution.which('lsusb')
  retval = {}
  bus = ''
  device = ''
  Facter::Util::Resolution.exec("lsusb -v 2>/dev/null").each_line do |line|
    Facter.debug line
    # only parse lines with text
    if not line =~ /.+/
      next
    end
    matches = line.match(/Bus (\d+) Device (\d+)/)
    if matches
      bus = "Bus: #{matches[1]}"
      device = "Device: #{matches[2]}"
      next
    end

    if not retval.has_key?(bus)
      retval[bus] = {}
    end
    if not retval[bus].has_key?(device)
      retval[bus][device] = {}
    end

    matches = line.match(/(bDeviceClass|bDeviceSubClass|bDeviceProtocol|iManufacturer|iProduct|iSerial)\s+\d\s+(.+)/)
    if matches
      retval[bus][device][matches[1].strip] = matches[2].strip
      next
    end

    matches = line.match(/idVendor\s+([\dabcdefx]+)\s(.+)/)
    if matches
      retval[bus][device]['idVendor'] = matches[1].strip
      retval[bus][device]['Vendor'] = matches[2].strip
      next
    end

    matches = line.match(/idProduct\s+([\dabcdefx]+)\s(.+)/)
    if matches
      retval[bus][device]['idProduct'] = matches[1].strip
      retval[bus][device]['Product'] = matches[2].strip
      next
    end
  end

  Facter.add(:lsusb) do
    confine :kernel => "Linux"
    setcode do
      retval
    end
  end
end
