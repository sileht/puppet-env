#
# string_to_hash.rb
#

module Puppet::Parser::Functions
  newfunction(:string_to_hash, :type => :rvalue) do |args|
    obj = args[0]
    key = args[1]
    if !obj.is_a?(Hash)
      return {key => obj}
    else
      return obj
    end
  end
end

# vim: set ts=2 sw=2 et :
