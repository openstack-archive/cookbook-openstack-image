default['openstack']['image_registry']['conf'].tap do |conf|
  # [DEFAULT] section
  conf['DEFAULT']['rpc_backend'] = node['openstack']['mq']['service_type']
  if node['openstack']['image']['syslog']['use']
    conf['DEFAULT']['log_config'] = '/etc/openstack/logging.conf'
  else
    conf['DEFAULT']['log_file'] = '/var/log/glance/registry.log'
  end

  # [paste_deploy] section
  conf['paste_deploy']['flavor'] = 'keystone'

  #  [keystone_authtoken] section
  conf['keystone_authtoken']['auth_plugin'] = 'v2password'
  conf['keystone_authtoken']['region_name'] = node['openstack']['region']
  conf['keystone_authtoken']['username'] = 'glance'
  conf['keystone_authtoken']['tenant_name'] = 'service'
  conf['keystone_authtoken']['signing_dir'] = '/var/cache/glance/registry' # none in docs
end
