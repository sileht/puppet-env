#
# convert_nil_to_hash.rb
#

module Puppet::Parser::Functions
  newfunction(:convert_nil_to_hash, :type => :rvalue) do |args|
    h = Marshal.load(Marshal.dump(args[0]))
    h.each do |k, v|
      if v.nil? or v == :undef
        h[k] = {}
      end
    end
    return h
  end
end

# vim: set ts=2 sw=2 et :
