#
# Cookbook Name:: glance
# Recipe:: keystone_registration
#
# Copyright 2013, AT&T
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

require "uri"

class ::Chef::Recipe
  include ::Openstack
end

identity_admin_endpoint = endpoint "identity-admin"

bootstrap_token = secret "secrets", "keystone_bootstrap_token"
auth_uri = ::URI.decode identity_admin_endpoint.to_s

registry_endpoint = endpoint "image-registry"
api_endpoint = endpoint "image-api"

# Register Image Service
keystone_register "Register Image Service" do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  service_name "glance"
  service_type "image"
  service_description "Glance Image Service"

  action :create_service
end

# Register Image Endpoint
keystone_register "Register Image Endpoint" do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  service_type "image"
  endpoint_region node["glance"]["region"]
  endpoint_adminurl api_endpoint.to_s
  endpoint_internalurl api_endpoint.to_s
  endpoint_publicurl api_endpoint.to_s

  action :create_endpoint
end

# Register Service Tenant
keystone_register "Register Service Tenant" do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  tenant_name node["glance"]["service_tenant_name"]
  tenant_description "Service Tenant"
  tenant_enabled "true" # Not required as this is the default

  action :create_tenant
end

# Register Service User
keystone_register "Register #{service_user} User" do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  tenant_name node["glance"]["service_tenant_name"]
  user_name service_user
  user_pass service_pass
  user_enabled "true" # Not required as this is the default

  action :create_user
end

## Grant Admin role to Service User for Service Tenant ##
keystone_register "Grant '#{service_role}' Role to #{service_user} User for #{service_tenant_name} Tenant" do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  tenant_name service_tenant_name
  user_name service_user
  role_name service_role

  action :grant_role
end
