# encoding: UTF-8
#
# Cookbook Name:: openstack-image
# Recipe:: identity_registration
#
# Copyright 2013, AT&T Services, Inc.
# Copyright 2013, Craig Tracey <craigtracey@gmail.com>
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

require 'uri'

class ::Chef::Recipe
  include ::Openstack
end

identity_admin_endpoint = admin_endpoint 'identity'

auth_url = ::URI.decode identity_admin_endpoint.to_s

interfaces = {
  public: { url: public_endpoint('image_api') },
  internal: { url: internal_endpoint('image_api') },
  admin: { url: admin_endpoint('image_api') },
}

admin_user = node['openstack']['identity']['admin_user']
admin_pass = get_password 'user', admin_user
admin_project = node['openstack']['identity']['admin_project']
admin_domain = node['openstack']['identity']['admin_domain_name']

service_pass = get_password 'service', 'openstack-image'
service_project =
  node['openstack']['image_api']['conf']['keystone_authtoken']['project_name']
service_user =
  node['openstack']['image_api']['conf']['keystone_authtoken']['username']
service_role = node['openstack']['image']['service_role']
service_domain_name = node['openstack']['image_api']['conf']['keystone_authtoken']['user_domain_name']
region = node['openstack']['region']

connection_params = {
  openstack_auth_url:     "#{auth_url}/auth/tokens",
  openstack_username:     admin_user,
  openstack_api_key:      admin_pass,
  openstack_project_name: admin_project,
  openstack_domain_name:    admin_domain,
}

# Register Image Service
openstack_service 'glance' do
  type 'image'
  connection_params connection_params
end

interfaces.each do |interface, res|
  # Register Image Endpoints
  openstack_endpoint 'image' do
    service_name 'glance'
    interface interface.to_s
    url res[:url].to_s
    region region
    connection_params connection_params
  end
end

# Register Service Tenant
openstack_project service_project do
  connection_params connection_params
end

# Register Service User
openstack_user service_user do
  domain_name service_domain_name
  role_name service_role
  project_name service_project
  password service_pass
  connection_params connection_params
  action [:create, :grant_role]
end
