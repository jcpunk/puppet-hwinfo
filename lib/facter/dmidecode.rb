if Facter::Util::Resolution.which('dmidecode')
  # http://wiki.xkyle.com/Custom_Puppet_Facts.html

  # Add remove things to query here
  query = { 
            'System Information'            => [ 'Version:' ],
            'Chassis Information'           => [ 'Number Of Power Cords:' ],
            'Memory Array'                  => [ 'Error Correction Type:', 'Maximum Capacity:', ]
  }
  
  # Run dmidecode only once
  output=%x{dmidecode 2>/dev/null}
  
  query.each_pair do |key, v|
    v.each do |value|
      output.split("Handle").each do |line|
        if line =~ /#{key}/  and line =~ /#{value} (\w.*)\n*./
          result = $1
          tag = key.split(' ')[0] + "_" + value.chomp(':').to_s.gsub(" ","_")
          Facter.add(tag) do
            confine :kernel => :Linux
            setcode do
              result
            end
          end # end facter.add
        end # end if line match
      end # end output line slpit
    end # end v.each
  end # end query.each_pair
end #endif
