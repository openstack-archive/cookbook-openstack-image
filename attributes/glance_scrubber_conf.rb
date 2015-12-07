default['openstack']['image-scrubber']['conf'].tap do |conf|
  # [DEFAULT] section
  conf['DEFAULT']['verbose'] = false
  if node['openstack']['image']['syslog']['use']
    conf['DEFAULT']['log_config'] = '/etc/openstack/logging.conf'
  else
    conf['DEFAULT']['log_file'] = '/var/log/glance/scrubber.log'
  end
end
