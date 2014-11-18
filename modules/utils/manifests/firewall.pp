


class utils::firewall(
  $zones,
  $policies,
  $hosts = {},
  $masqs = {},
  $ifaces = {},
  $rules = {},
  $tunnels = {},
  $proxyarps = {},
  $config = {},
  $fail2ban_filters = {},
  $fail2ban_jails = {},
){

  utils::firewall::zone{$zones:}

  $policy_names = keys($policies)
  utils::firewall::policy{$policy_names: policies => $policies}

  $iface_names = keys($ifaces)
  utils::firewall::iface{$iface_names: ifaces => $ifaces}

  create_resources(shorewall::host, $hosts, {})
  create_resources(shorewall::masq, $masqs, {})
  create_resources(shorewall::rule, $rules, {})
  create_resources(shorewall::tunnel, $tunnels, {})
  create_resources(shorewall::proxyarp, $proxyarps, {})
  create_resources(shorewall::config, $config, {})
  create_resources(fail2ban::filter, $fail2ban_filters, {})
  create_resources(fail2ban::jail, $fail2ban_jails, {})
}

define utils::firewall::policy($policies){
  $policy_set = merge({priority => "$name"}, $policies[$name])
  ensure_resource(shorewall::policy, $name, $policy_set)
}

define utils::firewall::iface($ifaces){
  $iface4_set = merge({proto => "ipv4", interface => "$name"}, $ifaces[$name])
  ensure_resource(shorewall::iface, "$name-4", $iface4_set)

  $iface6_set = merge({proto => "ipv6", interface => "$name"}, $ifaces[$name])
  ensure_resource(shorewall::iface, "$name-6", $iface6_set)
}

define utils::firewall::zone{
  shorewall::zone{"$name-4": zone => $name, type => 'ipv4'}
  shorewall::zone{"$name-6": zone => $name, type => 'ipv6'}
}
