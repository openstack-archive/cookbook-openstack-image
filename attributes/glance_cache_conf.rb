default['openstack']['image-cache']['conf'].tap do |conf|
  # [DEFAULT] section
  if node['openstack']['image']['syslog']['use']
    conf['DEFAULT']['log_config'] = '/etc/openstack/logging.conf'
  else
    conf['DEFAULT']['log_file'] = '/var/log/glance/image-cache.log'
  end
  conf['DEFAULT']['image_cache_dir'] = '/var/lib/glance/image-cache/' # none in docs
end
