# encoding: UTF-8
#
# Cookbook Name:: openstack-image
# Recipe:: image_upload
#
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

class ::Chef::Recipe
  include ::Openstack
end

if node['openstack']['image']['syslog']['use']
  include_recipe 'openstack-common::logging'
end

include_recipe 'openstack-common::client'

package 'curl' do
  action :upgrade
end

auth_uri = public_endpoint('identity').to_s
# admin_user = node['openstack']['image_api']['conf']['keystone_authtoken']['username']
# admin_pass = get_password admin_user, admin_pass
admin_user = node['openstack']['identity']['admin_user']
admin_pass = get_password 'user', admin_user
admin_project_name = node['openstack']['image_api']['conf']['keystone_authtoken']['project_name']
admin_project_domain_name = node['openstack']['image_api']['conf']['keystone_authtoken']['project_domain_name']
admin_domain = node['openstack']['image_api']['conf']['keystone_authtoken']['user_domain_name']

node['openstack']['image']['upload_images'].each do |img|
  type = 'unknown'
  type = node['openstack']['image']['upload_image_type'][img.to_sym] if node['openstack']['image']['upload_image_type'][img.to_sym]
  id = ''
  id = node['openstack']['image']['upload_image_id'][img.to_sym] if node['openstack']['image']['upload_image_id'][img.to_sym]
  openstack_image_image "Image setup for #{img}" do
    image_url node['openstack']['image']['upload_image'][img.to_sym]
    image_name img
    image_type type
    image_public true
    image_id id
    identity_user admin_user
    identity_pass admin_pass
    identity_tenant admin_project_name
    identity_uri auth_uri
    identity_user_domain_name admin_domain
    identity_project_domain_name admin_project_domain_name
    action :upload
  end
end
