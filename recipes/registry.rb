# encoding: UTF-8
#
# Cookbook Name:: openstack-image
# Recipe:: registry
#
# Copyright 2012, Rackspace US, Inc.
# Copyright 2013, Opscode, Inc.
# Copyright 2014, SUSE Linux, GmbH.
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

mq_service_type = node['openstack']['mq']['image']['service_type']

if mq_service_type == 'rabbitmq'
  node['openstack']['mq']['image']['rabbit']['ha'] && (rabbit_hosts = rabbit_servers)
  mq_password = get_password 'user', node['openstack']['mq']['image']['rabbit']['userid']
elsif mq_service_type == 'qpid'
  mq_password = get_password 'user', node['openstack']['mq']['image']['qpid']['username']
end

identity_endpoint = internal_endpoint 'identity-internal'
identity_admin_endpoint = admin_endpoint 'identity-admin'
registry_bind = internal_endpoint 'image-registry-bind'
service_pass = get_password 'service', 'openstack-image'

auth_uri = auth_uri_transform identity_endpoint.to_s, node['openstack']['image']['registry']['auth']['version']
identity_uri = identity_uri_transform(identity_admin_endpoint)

glance_user = node['openstack']['image']['user']
glance_group = node['openstack']['image']['group']

package 'curl' do
  options platform_options['package_overrides']
  action :upgrade
end

db_type = node['openstack']['db']['image']['service_type']
node['openstack']['db']['python_packages'][db_type].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options['package_overrides']
  end
end

platform_options['image_packages'].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options['package_overrides']
  end
end

directory node['openstack']['image']['registry']['auth']['cache_dir'] do
  owner glance_user
  group glance_group
  mode 00700
  recursive true
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
  mode 00700
end

template '/etc/glance/glance-registry.conf' do
  source 'glance-registry.conf.erb'
  owner node['openstack']['image']['user']
  group node['openstack']['image']['group']
  mode 00640
  variables(
    :registry_bind_address => registry_bind.host,
    :registry_bind_port => registry_bind.port,
    :sql_connection => sql_connection,
    :auth_uri => auth_uri,
    :identity_uri => identity_uri,
    notification_driver: node['openstack']['image']['notification_driver'],
    mq_service_type: mq_service_type,
    mq_password: mq_password,
    'service_pass' => service_pass,
    rabbit_hosts: rabbit_hosts
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
