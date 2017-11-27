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

class ::Chef::Recipe
  include ::Openstack
end

if node['openstack']['image']['syslog']['use']
  include_recipe 'openstack-common::logging'
end

platform_options = node['openstack']['image']['platform']

db_user = node['openstack']['db']['image']['username']
db_pass = get_password 'db', 'glance'
node.default['openstack']['image_registry']['conf_secrets']
  .[]('database')['connection'] = db_uri('image', db_user, db_pass)

if node['openstack']['mq']['service_type'] == 'rabbit'
  node.default['openstack']['image_registry']['conf_secrets']['DEFAULT']['transport_url'] = rabbit_transport_url 'image'
end

identity_endpoint = public_endpoint 'identity'
registry_bind = node['openstack']['bind_service']['all']['image_registry']
registry_bind_address = bind_address registry_bind

node.default['openstack']['image_registry']['conf_secrets']
  .[]('keystone_authtoken')['password'] = get_password 'service', 'openstack-image'

auth_url = auth_uri_transform identity_endpoint.to_s, node['openstack']['api']['auth']['version']
glance_user = node['openstack']['image']['user']
glance_group = node['openstack']['image']['group']

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

directory node['openstack']['image_registry']['conf']['keystone_authtoken']['signing_dir'] do
  owner glance_user
  group glance_group
  mode 0o0700
  recursive true
end

file '/var/lib/glance/glance.sqlite' do
  action :delete
  not_if { node['openstack']['db']['image']['service_type'] == 'sqlite' }
end

node.default['openstack']['image_registry']['conf'].tap do |conf|
  # [DEFAULT] section
  conf['DEFAULT']['bind_host'] = registry_bind_address
  conf['DEFAULT']['bind_port'] = registry_bind['port']

  # [keystone_authtoken] section
  conf['keystone_authtoken']['auth_url'] = auth_url
end

# merge all config options and secrets to be used in the nova.conf.erb
glance_registry_conf_options = merge_config_options 'image_registry'

template '/etc/glance/glance-registry.conf' do
  source 'openstack-service.conf.erb'
  cookbook 'openstack-common'
  owner node['openstack']['image']['user']
  group node['openstack']['image']['group']
  mode 0o0640
  variables(
    service_config: glance_registry_conf_options
  )
end
# delete all secrets saved in the attribute
# node['openstack']['image_registry']['conf_secrets'] after creating the glance-registry.conf
ruby_block "delete all attributes in node['openstack']['image_registry']['conf_secrets']" do
  block do
    node.rm(:openstack, :image_registry, :conf_secrets)
  end
end

execute 'glance-manage db_sync' do
  user glance_user
  group glance_group
  only_if { node['openstack']['db']['image']['migrate'] }
end

service 'glance-registry' do
  service_name platform_options['image_registry_service']
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/glance/glance-registry.conf]', :immediately
end
