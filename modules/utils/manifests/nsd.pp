

class utils::nsd(){

  package{'nsd':}
  service{'nsd':
    ensure  => running,
    require => Package['nsd'],
  }

  file{'/etc/nsd/nsd.conf':
    content => inline_template('# managed by puppet
server:
<% scope.call_function("hiera_hash", ["utils::nsd::config", {}]).each do |k, v| -%>
    <%= k %>: <%= v %>
<% end -%>
<% scope.call_function("hiera_hash", ["utils::nsd::configs", {}]).each do |k, vs| -%>
<%  vs.each do |v| -%>
    <%= k %>: <%= v %>
<% end -%>
<% end -%>
<% scope.call_function("hiera_hash", ["utils::nsd::keys", {}]).each do |name, options| -%>
key:
    name: <%= name %>
<%   options.each do |k, v| -%>
    <%= k %>: <%= v %>
<%   end -%>
<% end %>
<% scope.call_function("hiera_hash", ["utils::nsd::zones", {}]).each do |name, options| -%>
zone:
    name: "<%= name %>"
    zonefile: "<%= name %>/zone.db<%= options["signed"] ? ".signed" : "" %>"
<%   filtered_options = options.select {|k, v| !["signed", "content"].include?(k) } -%>
<%   filtered_options.each do |k, v| -%>
    <%= k %>: <%= v %>
<%   end -%>
<% end %>
'),
    require => Package['nsd'],
    notify  => Service['nsd'],
  }
  #  $zonesdir = hiera_hash(["utils::nsd::config"], {})["zonesdir"]
  #  if $zonesdir{
  #    create_resource(utils::nsd::zones, keys(hiera_hash("utils::nsd::zones", {})))
  #  }
}

define utils::nsd::zones($zonesdir){
  $zones = hiera_hash("utils::nsd::zones")
  $zone = $zones[$name]
  if $zone['content'] {
    if $zone['signed'] {
      $zonefile = "${zonesdir}/${name}/zone.db"
    } else {
      $zonefile = "${zonesdir}/${name}/zone.db.signed"
    }
    file{$zonefile:
      content => template($zone['content'])
    }
  }
}
