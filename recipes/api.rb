#
# Cookbook Name:: glance
# Recipe:: api
#
# Copyright 2009-2012, Rackspace Hosting, Inc.
# Copyright 2012, Opscode, Inc.
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
include_recipe "glance::glance-rsyslog"

platform_options = node["glance"]["platform"]

package "curl" do
  action :upgrade
end

package "python-keystone" do
    action :install
end

platform_options["glance_packages"].each do |pkg|
  package pkg do
    action :upgrade
  end
end

service "glance-api" do
  service_name platform_options["glance_api_service"]
  supports :status => true, :restart => true
  action :enable
end

# FIXME: this is broken.  Joe, Wilk, fix this.
template "/usr/share/pyshared/glance/store/swift.py" do
  source "swift.py"
  group "root"
  owner "root"
  mode "0644"
  only_if do platform?(%w{debian ubuntu}) end
  notifies :restart, resources(:service => "glance-api"), :immediately
end

directory "/etc/glance" do
  action :create
  group "glance"
  owner "glance"
  mode "0700"
end

# FIXME: seems like misfeature
template "/etc/glance/policy.json" do
  source "policy.json.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, resources(:service => "glance-api"), :immediately
  not_if do
    File.exists?("/etc/glance/policy.json")
  end
end

rabbit_info = get_settings_by_role("rabbitmq-server", "rabbitmq") # FIXME: access

ks_admin_endpoint = get_access_endpoint("keystone", "keystone", "admin-api")
ks_service_endpoint = get_access_endpoint("keystone", "keystone","service-api")
keystone = get_settings_by_role("keystone", "keystone")
glance = get_settings_by_role("glance-api", "glance")

registry_endpoint = get_access_endpoint("glance-registry", "glance", "registry")
api_endpoint = get_bind_endpoint("glance", "api")

template "/etc/glance/glance-api.conf" do
  source "glance-api.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    "api_bind_address" => api_endpoint["host"],
    "api_bind_port" => api_endpoint["port"],
    "registry_ip_address" => registry_endpoint["host"],
    "registry_port" => registry_endpoint["port"],
    "use_syslog" => node["glance"]["syslog"]["use"],
    "log_facility" => node["glance"]["syslog"]["facility"],
    "rabbit_ipaddress" => rabbit_info["ipaddress"],    #FIXME!
    "keystone_api_ipaddress" => ks_admin_endpoint["host"],
    "keystone_service_port" => ks_service_endpoint["port"],
    "service_user" => glance["service_user"],
    "service_pass" => glance["service_pass"],
    "service_tenant_name" => glance["service_tenant_name"],
    "default_store" => glance["api"]["default_store"],
    "swift_large_object_size" => glance["api"]["swift"]["store_large_object_size"],
    "swift_large_object_chunk_size" => glance["api"]["swift"]["store_large_object_chunk_size"],
    "swift_store_container" => glance["api"]["swift"]["store_container"]
  )
  notifies :restart, resources(:service => "glance-api"), :immediately
end

template "/etc/glance/glance-api-paste.ini" do
  source "glance-api-paste.ini.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    "keystone_api_ipaddress" => ks_admin_endpoint["host"],
    "keystone_service_port" => ks_service_endpoint["port"],
    "keystone_admin_port" => ks_admin_endpoint["port"],
    "keystone_admin_token" => keystone["admin_token"],
    "service_tenant_name" => node["glance"]["service_tenant_name"],
    "service_user" => node["glance"]["service_user"],
    "service_pass" => node["glance"]["service_pass"]
  )
  notifies :restart, resources(:service => "glance-api"), :immediately
end

template "/etc/glance/glance-scrubber.conf" do
  source "glance-scrubber.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    "registry_ip_address" => registry_endpoint["host"],
    "registry_port" => registry_endpoint["port"]
  )
end

template "/etc/glance/glance-scrubber-paste.ini" do
  source "glance-scrubber-paste.ini.erb"
  owner "root"
  group "root"
  mode "0644"
end

# Register Image Service
keystone_register "Register Image Service" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_name "glance"
  service_type "image"
  service_description "Glance Image Service"
  action :create_service
end

# Register Image Endpoint
keystone_register "Register Image Endpoint" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_type "image"
  endpoint_region "RegionOne"
  endpoint_adminurl api_endpoint["uri"]
  endpoint_internalurl api_endpoint["uri"]
  endpoint_publicurl api_endpoint["uri"]
  action :create_endpoint
end

if node["glance"]["image_upload"]
  # TODO(breu): the environment needs to be derived from a search
  # TODO(shep): this whole bit is super dirty.. and needs some love.
  node["glance"]["images"].each do |img|
    Chef::Log.info("Checking to see if #{img.to_s}-image should be uploaded.")

    keystone_admin_user = keystone["admin_user"]
    keystone_admin_password = keystone["users"][keystone_admin_user]["password"]
    keystone_tenant = keystone["users"][keystone_admin_user]["default_tenant"]


    bash "default image setup for #{img.to_s}" do
      cwd "/tmp"
      user "root"
      environment ({"OS_USERNAME" => keystone_admin_user,
                    "OS_PASSWORD" => keystone_admin_password,
                    "OS_TENANT_NAME" => keystone_tenant,
                    "OS_AUTH_URL" => ks_admin_endpoint["uri"]})
      code <<-EOH
        set -e
        set -x
        mkdir -p images/#{img.to_s}
        cd images/#{img.to_s}

        curl #{node["glance"]["image"][img.to_sym]} | tar -zx
        image_name=$(basename #{node["glance"]["image"][img]} .tar.gz)

        image_name=${image_name%-multinic}

        kernel_file=$(ls *vmlinuz-virtual | head -n1)
        if [ ${#kernel_file} -eq 0 ]; then
           kernel_file=$(ls *vmlinuz | head -n1)
        fi

        ramdisk=$(ls *-initrd | head -n1)
        if [ ${#ramdisk} -eq 0 ]; then
            ramdisk=$(ls *-loader | head -n1)
        fi

        kernel=$(ls *.img | head -n1)

        kid=$(glance --silent-upload add name="${image_name}-kernel" is_public=true disk_format=aki container_format=aki < ${kernel_file} | cut -d: -f2 | sed 's/ //')
        rid=$(glance --silent-upload add name="${image_name}-initrd" is_public=true disk_format=ari container_format=ari < ${ramdisk} | cut -d: -f2 | sed 's/ //')
        glance --silent-upload add name="#{img.to_s}-image" is_public=true disk_format=ami container_format=ami kernel_id=$kid ramdisk_id=$rid < ${kernel}
      EOH
      not_if "glance -f -I #{keystone_admin_user} -K #{keystone_admin_password} -T #{keystone_tenant} -N #{ks_admin_endpoint["uri"]} index | grep #{img.to_s}-image"
    end
  end
end
