#
# prep_file_hash_with_content.rb
#

module Puppet::Parser::Functions
  newfunction(:prep_file_hash_with_content, :type => :rvalue) do |args|
    require 'erb'
    h = Marshal.load(Marshal.dump(args[0]))
    h.each do |k, v|
      if !v.is_a?(Hash)
        content = v
        if !v.include?("\n") and Puppet::FileSystem.exist?(v)
          f = Puppet::FileSystem.read(v)
          content = Puppet::Parser::TemplateWrapper.new(self).result(f)
        end
        h[k] = { :content  => content }
      else
        v.each do |sk, sv|
          if sk == 'content' and !sv.include?("\n") and Puppet::FileSystem.exist?(sv)
            f = Puppet::FileSystem.read(sv)
            v[sk] = Puppet::Parser::TemplateWrapper.new(self).result(f)
          end
        end
      end
    end
    return h
  end
end

# vim: set ts=2 sw=2 et :
