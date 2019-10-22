# encoding: UTF-8
#
# Cookbook Name:: openstack-image
# Recipe:: api
#
# Copyright 2012, Rackspace US, Inc.
# Copyright 2012-2013, Opscode, Inc.
# Copyright 2012-2013, AT&T Services, Inc.
# Copyright 2013, Craig Tracey <craigtracey@gmail.com>
# Copyright 2013, IBM Corp.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
require 'uri'

class ::Chef::Recipe
  include ::Openstack
end

include_recipe 'openstack-common::client'

if node['openstack']['image']['syslog']['use']
  include_recipe 'openstack-common::logging'
end

platform_options = node['openstack']['image']['platform']

platform_options['image_packages'].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options['package_overrides']
  end
end

directory '/etc/glance' do
  owner node['openstack']['image']['user']
  group node['openstack']['image']['group']
  mode 0o0700
end

if node['openstack']['image_api']['conf']['glance_store']['default_store'] == 'file'
  node.default['openstack']['image_api']['conf']['glance_store']['filesystem_store_datadir'] =
    '/var/lib/glance/images'
  directory node['openstack']['image_api']['conf']['glance_store']['filesystem_store_datadir'] do
    owner node['openstack']['image']['user']
    group node['openstack']['image']['group']
    mode 0o0750
    recursive true
  end
end

node.default['openstack']['image_api']['conf_secrets']
.[]('keystone_authtoken')['password'] =
  get_password 'service', 'openstack-image'

identity_endpoint = internal_endpoint 'identity'
auth_url = ::URI.decode identity_endpoint.to_s

db_user = node['openstack']['db']['image']['username']
db_pass = get_password 'db', 'glance'
node.default['openstack']['image_api']['conf_secrets']
.[]('database')['connection'] =
  db_uri('image', db_user, db_pass)

if node['openstack']['mq']['service_type'] == 'rabbit'
  node.default['openstack']['image_api']['conf_secrets']['DEFAULT']['transport_url'] = rabbit_transport_url 'image'
end

api_bind = node['openstack']['bind_service']['all']['image_api']
api_bind_address = bind_address api_bind

node.default['openstack']['image_api']['conf'].tap do |conf|
  # [DEFAULT] section
  conf['DEFAULT']['bind_host']  = api_bind_address
  conf['DEFAULT']['bind_port']  = api_bind['port']
  # [keystone_authtoken] section
  conf['keystone_authtoken']['auth_url'] = auth_url
end

# merge all config options and secrets
glance_api_conf = merge_config_options 'image_api'
glance_cache_conf = merge_config_options 'image_cache'
glance_scrubber_conf = merge_config_options 'image_scrubber'

template '/etc/glance/glance-api.conf' do
  source 'openstack-service.conf.erb'
  cookbook 'openstack-common'
  owner node['openstack']['image']['user']
  group node['openstack']['image']['group']
  mode 0o0640
  variables(
    service_config: glance_api_conf
  )
end

template '/etc/glance/glance-cache.conf' do
  source 'openstack-service.conf.erb'
  cookbook 'openstack-common'
  owner node['openstack']['image']['user']
  group node['openstack']['image']['group']
  mode 0o0640
  variables(
    service_config: glance_cache_conf
  )
end

template '/etc/glance/glance-scrubber.conf' do
  source 'openstack-service.conf.erb'
  cookbook 'openstack-common'
  owner node['openstack']['image']['user']
  group node['openstack']['image']['group']
  mode 0o0640
  variables(
    service_config: glance_scrubber_conf
  )
end

%w(image_api image_cache image_scrubber).each do |service|
  # delete all secrets saved in the attribute
  # node['openstack']['pi]['conf_secrets'] after creating the glance-api.conf
  ruby_block "delete all attributes in node['openstack']['#{service}']['conf_secrets']" do
    block do
      node.rm('openstack', service, 'conf_secrets')
    end
  end
end

execute 'glance-manage db_sync' do
  user node['openstack']['image']['user']
  group node['openstack']['image']['group']
  only_if { node['openstack']['db']['image']['migrate'] }
end

# Configure glance-cache-pruner to run every 30 minutes
cron 'glance-cache-pruner' do
  minute '*/30'
  command "/usr/bin/glance-cache-pruner #{node['openstack']['image']['cron']['redirection']}"
end

# Configure glance-cache-cleaner to run at 00:01 everyday
cron 'glance-cache-cleaner' do
  minute '01'
  hour '00'
  command "/usr/bin/glance-cache-cleaner #{node['openstack']['image']['cron']['redirection']}"
end

# Ensure the owner/group of image cache directory is correct
directory node['openstack']['image']['cache']['dir'] do
  owner node['openstack']['image']['user']
  group node['openstack']['image']['group']
  recursive true
  mode 0o0755
end

service 'glance-api' do
  service_name platform_options['image_api_service']
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, [
    'template[/etc/glance/glance-scrubber.conf]',
    'template[/etc/glance/glance-cache.conf]',
    'template[/etc/glance/glance-api.conf]',
  ], :immediately
end
