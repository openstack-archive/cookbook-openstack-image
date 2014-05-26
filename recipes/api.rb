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
# limitations under the License.
#

require 'uri'

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

if node['openstack']['image']['syslog']['use']
  include_recipe 'openstack-common::logging'
end

platform_options = node['openstack']['image']['platform']

package 'python-keystoneclient' do
  options platform_options['package_overrides']
  action :upgrade
end

package 'curl' do
  options platform_options['package_overrides']
  action :upgrade
end

platform_options['image_packages'].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options['package_overrides']
  end
end

if node['openstack']['image']['api']['default_store'] == 'swift'
  platform_options['swift_packages'].each do |pkg|
    package pkg do
      action :upgrade
      options platform_options['package_overrides']
    end
  end

elsif node['openstack']['image']['api']['default_store'] == 'rbd'
  rbd_user = node['openstack']['image']['api']['rbd']['rbd_store_user']
  rbd_key = get_password 'service', node['openstack']['image']['api']['rbd']['key_name']

  include_recipe 'openstack-common::ceph_client'

  platform_options['ceph_packages'].each do |pkg|
    package pkg do
      options platform_options['package_overrides']
      action :upgrade
    end
  end

  template "/etc/ceph/ceph.client.#{rbd_user}.keyring" do
    source 'ceph.client.keyring.erb'
    cookbook 'openstack-common'
    owner node['openstack']['image']['user']
    group node['openstack']['image']['group']
    mode 00600
    variables(
      name: rbd_user,
      key: rbd_key
    )
  end
end

service 'glance-api' do
  service_name platform_options['image_api_service']
  supports status: true, restart: true

  action :enable
end

directory '/etc/glance' do
  owner node['openstack']['image']['user']
  group node['openstack']['image']['group']
  mode  00700
end

directory ::File.dirname node['openstack']['image']['api']['auth']['cache_dir'] do
  owner node['openstack']['image']['user']
  group node['openstack']['image']['group']
  mode 00700
end

glance = node['openstack']['image']

identity_endpoint = endpoint 'identity-api'
identity_admin_endpoint = endpoint 'identity-admin'
service_pass = get_password 'service', 'openstack-image'

auth_uri = auth_uri_transform identity_endpoint.to_s, node['openstack']['image']['api']['auth']['version']

db_user = node['openstack']['db']['image']['username']
db_pass = get_password 'db', 'glance'
sql_connection = db_uri('image', db_user, db_pass)

mq_service_type = node['openstack']['mq']['image']['service_type']

if mq_service_type == 'rabbitmq'
  mq_password = get_password 'user', node['openstack']['mq']['image']['rabbit']['userid']
elsif mq_service_type == 'qpid'
  mq_password = get_password 'user', node['openstack']['mq']['image']['qpid']['username']
end

registry_endpoint = endpoint 'image-registry'
api_bind = endpoint 'image-api-bind'

# Possible combinations of options here
# - default_store=file
#     * no other options required
# - default_store=swift
#     * if swift_store_auth_address is not defined
#         - default to local swift
#     * else if swift_store_auth_address is defined
#         - get swift_store_auth_address, swift_store_user, swift_store_key, and
#           swift_store_auth_version from the node attributes and use them to connect
#           to the swift compatible API service running elsewhere - possibly
#           Rackspace Cloud Files.
if glance['api']['swift_store_auth_address'].nil?
  swift_store_auth_address = auth_uri
  swift_store_user = "#{glance['service_tenant_name']}_#{glance['service_user']}"
  swift_user_tenant = nil
  swift_store_key = service_pass
  swift_store_auth_version = 2
else
  swift_store_auth_address = glance['api']['swift_store_auth_address']
  swift_user_tenant = glance['api']['swift_user_tenant']
  swift_store_user = glance['api']['swift_store_user']
  swift_store_key = get_password 'service', swift_store_user
  swift_store_auth_version = glance['api']['swift_store_auth_version']
end

glance_flavor = 'keystone'
if glance['api']['cache_management']
  glance_flavor += '+cachemanagement'
elsif glance['api']['caching']
  glance_flavor += '+caching'
end

unless node['openstack']['image']['api']['vmware']['vmware_server_host'].empty?
  vmware_server_password = get_secret node['openstack']['image']['api']['vmware']['secret_name']
end

template '/etc/glance/glance-api.conf' do
  source 'glance-api.conf.erb'
  owner node['openstack']['image']['user']
  group node['openstack']['image']['group']
  mode   00644
  variables(
    api_bind_address: api_bind.host,
    api_bind_port: api_bind.port,
    registry_ip_address: registry_endpoint.host,
    registry_port: registry_endpoint.port,
    sql_connection: sql_connection,
    glance_flavor: glance_flavor,
    auth_uri: auth_uri,
    identity_admin_endpoint: identity_admin_endpoint,
    service_pass: service_pass,
    swift_store_key: swift_store_key,
    swift_user_tenant: swift_user_tenant,
    swift_store_user: swift_store_user,
    swift_store_auth_address: swift_store_auth_address,
    swift_store_auth_version: swift_store_auth_version,
    notification_driver: node['openstack']['image']['notification_driver'],
    mq_service_type: mq_service_type,
    mq_password: mq_password,
    vmware_server_password: vmware_server_password
  )

  notifies :restart, 'service[glance-api]', :immediately
end

template '/etc/glance/glance-api-paste.ini' do
  source 'glance-api-paste.ini.erb'
  owner node['openstack']['image']['user']
  group node['openstack']['image']['group']
  mode   00644

  notifies :restart, 'service[glance-api]', :immediately
end

template '/etc/glance/glance-cache.conf' do
  source 'glance-cache.conf.erb'
  owner node['openstack']['image']['user']
  group node['openstack']['image']['group']
  mode   00644
  variables(
    registry_ip_address: registry_endpoint.host,
    registry_port: registry_endpoint.port,
    vmware_server_password: vmware_server_password
  )

  notifies :restart, 'service[glance-api]', :immediately
end

# TODO(jaypipes) I don't think this even exists or at least isn't
# used, since the Glance cache middleware goes in the api-paste.ini...
template '/etc/glance/glance-cache-paste.ini' do
  source 'glance-cache-paste.ini.erb'
  owner node['openstack']['image']['user']
  group node['openstack']['image']['group']
  mode   00644

  notifies :restart, 'service[glance-api]', :immediately
end

template '/etc/glance/glance-scrubber.conf' do
  source 'glance-scrubber.conf.erb'
  owner node['openstack']['image']['user']
  group node['openstack']['image']['group']
  mode   00644
  variables(
    registry_ip_address: registry_endpoint.host,
    registry_port: registry_endpoint.port
  )
end

# Configure glance-cache-pruner to run every 30 minutes
cron 'glance-cache-pruner' do
  minute '*/30'
  command "/usr/bin/glance-cache-pruner #{node['openstack']['image']['cron']['redirection']}"
end

# Configure glance-cache-cleaner to run at 00:01 everyday
cron 'glance-cache-cleaner' do
  minute  '01'
  hour    '00'
  command "/usr/bin/glance-cache-cleaner #{node['openstack']['image']['cron']['redirection']}"
end

template '/etc/glance/glance-scrubber-paste.ini' do
  source 'glance-scrubber-paste.ini.erb'
  owner node['openstack']['image']['user']
  group node['openstack']['image']['group']
  mode   00644
end

if node['openstack']['image']['api']['default_store'] == 'file'
  directory node['openstack']['image']['filesystem_store_datadir'] do
    owner node['openstack']['image']['user']
    group node['openstack']['image']['group']
    mode 00750
    recursive true
  end
end
