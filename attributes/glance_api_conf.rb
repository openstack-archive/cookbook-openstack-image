default['openstack']['image_api']['conf'].tap do |conf|
  # [DEFAULT] section
  if node['openstack']['image']['syslog']['use']
    conf['DEFAULT']['log_config'] = '/etc/openstack/logging.conf'
  else
    conf['DEFAULT']['log_file'] = '/var/log/glance/api.log'
  end
  conf['DEFAULT']['enabled_backends'] = 'file:file,http:http'

  # [glance_store] section
  conf['glance_store']['default_backend'] = 'file'

  # [paste_deploy] section
  conf['paste_deploy']['flavor'] = 'keystone'

  # [keystone_authtoken] section
  conf['keystone_authtoken']['auth_type'] = 'password'
  conf['keystone_authtoken']['region_name'] = node['openstack']['region']
  conf['keystone_authtoken']['username'] = 'glance'
  conf['keystone_authtoken']['project_name'] = 'admin'
  conf['keystone_authtoken']['user_domain_name'] = 'Default'
  conf['keystone_authtoken']['project_domain_name'] = 'Default'
end
