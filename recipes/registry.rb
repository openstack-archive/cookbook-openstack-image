# encoding: UTF-8
#
# Cookbook Name:: openstack-image
# Recipe:: registry
#
# Copyright 2012, Rackspace US, Inc.
# Copyright 2013, Opscode, Inc.
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

db_user = node['openstack']['db']['image']['username']
db_pass = get_password 'db', 'glance'
sql_connection = db_uri('image', db_user, db_pass)

identity_endpoint = endpoint 'identity-api'
identity_admin_endpoint = endpoint 'identity-admin'
registry_bind = endpoint 'image-registry-bind'
service_pass = get_password 'service', 'openstack-image'

auth_uri = auth_uri_transform identity_endpoint.to_s, node['openstack']['image']['registry']['auth']['version']

glance_user = node['openstack']['image']['user']
glance_group = node['openstack']['image']['group']

package 'curl' do
  options platform_options['package_overrides']
  action :upgrade
end

pkg_key = "#{node['openstack']['db']['image']['service_type']}_python_packages"
if platform_options.key?(pkg_key)
  platform_options[pkg_key].each do |pkg|
    package pkg do
      action :upgrade
      options platform_options['package_overrides']
    end
  end
end

platform_options['image_packages'].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options['package_overrides']
  end
end

directory ::File.dirname(node['openstack']['image']['registry']['auth']['cache_dir']) do
  owner glance_user
  group glance_group
  mode 00700
end

service 'glance-registry' do
  service_name platform_options['image_registry_service']
  supports status: true, restart: true

  action :enable
end

file '/var/lib/glance/glance.sqlite' do
  action :delete
  not_if { node['openstack']['db']['image']['service_type'] == 'sqlite' }
end

directory '/etc/glance' do
  owner glance_user
  group glance_group
  mode  00700
end

template '/etc/glance/glance-registry.conf' do
  source 'glance-registry.conf.erb'
  owner  'root'
  group  'root'
  mode   00644
  variables(
    :registry_bind_address => registry_bind.host,
    :registry_bind_port => registry_bind.port,
    :sql_connection => sql_connection,
    :auth_uri => auth_uri,
    'identity_admin_endpoint' => identity_admin_endpoint,
    'service_pass' => service_pass
  )

  notifies :restart, 'service[glance-registry]', :immediately
end

# Having to manually version the database because of Ubuntu bug
# https://bugs.launchpad.net/ubuntu/+source/glance/+bug/981111
execute 'glance-manage version_control 0' do
  user glance_user
  group glance_group
  not_if 'glance-manage db_version', user: glance_user, group: glance_group
  only_if { platform_family?('debian') }
end

execute 'glance-manage db_sync' do
  user glance_user
  group glance_group
  only_if { node['openstack']['db']['image']['migrate'] }
end

template '/etc/glance/glance-registry-paste.ini' do
  source 'glance-registry-paste.ini.erb'
  owner  'root'
  group  'root'
  mode   00644

  notifies :restart, 'service[glance-registry]', :immediately
end
