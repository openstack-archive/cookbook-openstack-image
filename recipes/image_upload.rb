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

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

if node['openstack']['image']['syslog']['use']
  include_recipe 'openstack-common::logging'
end

platform_options = node['openstack']['image']['platform']
platform_options['image_client_packages'].each do |pkg|
  package pkg do
    action :upgrade
  end
end

identity_endpoint = endpoint 'identity-api'

# For glance client, only identity v2 is supported. See discussion on
# https://bugs.launchpad.net/openstack-chef/+bug/1207504
# So here auth_uri can not be transformed.
auth_uri = identity_endpoint.to_s

service_pass = get_password 'service', 'openstack-image'
service_tenant_name = node['openstack']['image']['service_tenant_name']
service_user = node['openstack']['image']['service_user']

node['openstack']['image']['upload_images'].each do |img|
  type = 'unknown'
  type = node['openstack']['image']['upload_image_type'][img.to_sym] if node['openstack']['image']['upload_image_type'][img.to_sym]

  openstack_image_image "Image setup for #{img.to_s}" do
    image_url node['openstack']['image']['upload_image'][img.to_sym]
    image_name img
    image_type type
    identity_user service_user
    identity_pass service_pass
    identity_tenant service_tenant_name
    identity_uri auth_uri
    action :upload
  end
end
