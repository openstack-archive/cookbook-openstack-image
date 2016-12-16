default['openstack']['image_registry']['conf'].tap do |conf|
  # [DEFAULT] section
  if node['openstack']['image']['syslog']['use']
    conf['DEFAULT']['log_config'] = '/etc/openstack/logging.conf'
  else
    conf['DEFAULT']['log_file'] = '/var/log/glance/registry.log'
  end

  # [paste_deploy] section
  conf['paste_deploy']['flavor'] = 'keystone'

  #  [keystone_authtoken] section
  conf['keystone_authtoken']['auth_type'] = 'v3password'
  conf['keystone_authtoken']['region_name'] = node['openstack']['region']
  conf['keystone_authtoken']['username'] = 'glance'
  conf['keystone_authtoken']['project_name'] = 'service'
  conf['keystone_authtoken']['user_domain_name'] = 'Default'
  conf['keystone_authtoken']['signing_dir'] = '/var/cache/glance/registry' # none in docs
  conf['keystone_authtoken']['project_domain_name'] = 'Default'
end
