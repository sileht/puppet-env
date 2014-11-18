

class utils::phpfpm($phpconfigs = {}){
  file { '/etc/php/7.4/fpm/conf.d/perso.ini':
    ensure  => 'present',
    content => inline_template('
<% @phpconfigs.each do |host, confs| -%>
<%   if host == "PHP" -%>
[PHP]
<%   else -%>
[HOST=<%= host %>]
<%   end -%>
<%   confs.each do |key, value| -%>
<%= key %> = <%= value %>
<%   end -%>

<% end -%>
    '),
    notify  => Class['phpfpm::service'],
  }
}
