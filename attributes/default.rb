#
# Cookbook Name:: glance
# Attributes:: default
#
# Copyright 2012, Rackspace US, Inc.
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

########################################################################
# Toggles - These can be overridden at the environment level
default["developer_mode"] = false  # we want secure passwords by default
########################################################################

default["glance"]["services"]["api"]["scheme"] = "http"
default["glance"]["services"]["api"]["network"] = "public"
default["glance"]["services"]["api"]["port"] = 9292
default["glance"]["services"]["api"]["path"] = "/v1"

default["glance"]["services"]["registry"]["scheme"] = "http"
default["glance"]["services"]["registry"]["network"] = "public"
default["glance"]["services"]["registry"]["port"] = 9191
default["glance"]["services"]["registry"]["path"] = "/v1"

default["glance"]["db"]["name"] = "glance"
default["glance"]["db"]["username"] = "glance"

# TODO: These may need to be glance-registry specific.. and looked up by glance-api
default["glance"]["service_tenant_name"] = "service"
default["glance"]["service_user"] = "glance"
default["glance"]["service_role"] = "admin"
default["glance"]["api"]["default_store"] = "file"
default["glance"]["api"]["swift"]["store_container"] = "glance"
default["glance"]["api"]["swift"]["store_large_object_size"] = "200"
default["glance"]["api"]["swift"]["store_large_object_chunk_size"] = "200"
default["glance"]["api"]["cache"]["image_cache_max_size"] = "10737418240"

# Default Image Locations
default["glance"]["image_upload"] = false
default["glance"]["images"] = [ "cirros" ]
default["glance"]["image"]["precise"] = "http://cloud-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64-disk1.img"
default["glance"]["image"]["oneiric"] = "http://cloud-images.ubuntu.com/oneiric/current/oneiric-server-cloudimg-amd64-disk1.img"
default["glance"]["image"]["natty"] = "http://cloud-images.ubuntu.com/natty/current/natty-server-cloudimg-amd64-disk1.img"
default["glance"]["image"]["cirros"] = "https://launchpadlibrarian.net/83305348/cirros-0.3.0-x86_64-disk.img"

# logging attribute
default["glance"]["syslog"]["use"] = false
default["glance"]["syslog"]["facility"] = "LOG_LOCAL2"
default["glance"]["syslog"]["config_facility"] = "local2"

# platform-specific settings
case platform
when "fedora", "redhat", "centos"
  default["glance"]["platform"] = {
    "mysql_python_packages" => [ "MySQL-python" ],
    "glance_packages" => [ "openstack-glance", "openstack-swift" ],
    "glance_api_service" => "openstack-glance-api",
    "glance_registry_service" => "openstack-glance-registry",
    "glance_api_process_name" => "glance-api",
    "package_overrides" => ""
  }
when "ubuntu"
  default["glance"]["platform"] = {
    "mysql_python_packages" => [ "python-mysqldb" ],
    "glance_packages" => [ "glance", "python-swift" ],
    "glance_api_service" => "glance-api",
    "glance_registry_service" => "glance-registry",
    "glance_registry_process_name" => "glance-registry",
    "package_overrides" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
end
