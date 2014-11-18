#
# inject_in_hashes.rb
#

module Puppet::Parser::Functions
  newfunction(:inject_in_hashes, :type => :rvalue) do |args|
    Puppet::Parser::Functions.autoloader.loadall
    h = Marshal.load(Marshal.dump(args[0]))
    to_inject = args[1]
    h.each do |k, v|
      h[k] = function_merge([to_inject, v])
    end
    return h
  end
end

# vim: set ts=2 sw=2 et :
