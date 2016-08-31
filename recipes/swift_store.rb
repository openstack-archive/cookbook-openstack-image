# encoding: UTF-8
#
# Cookbook Name:: openstack-image
# Recipe:: swift_store
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

class ::Chef::Recipe
  include ::Openstack
end

platform_options = node['openstack']['image']['platform']

platform_options['swift_packages'].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options['package_overrides']
  end
end

identity_endpoint = public_endpoint 'identity'
swift_store_auth_address =
  auth_uri_transform identity_endpoint.to_s, node['openstack']['api']['auth']['version']
tenant = node['openstack']['image_api']['conf']['keystone_authtoken']['project']
user = node['openstack']['image_api']['conf']['keystone_authtoken']['user']
swift_store_user =  "#{tenant}_#{user}"
swift_user_tenant = nil
node.default['openstack']['image_api']['conf_secrets']
  .[]('glance_store')['swift_store_key'] =
  get_password 'service', 'openstack-image'
swift_store_auth_version = 2

node.default['openstack']['image_api']['conf']['glance_store'].tap do |store|
  store['default_store'] = 'swift'
  store['swift_store_auth_version'] = swift_store_auth_version
  store['swift_store_auth_address'] = swift_store_auth_address
  store['swift_store_user'] = "#{swift_user_tenant}:#{swift_store_user}"
end
