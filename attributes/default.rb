#
# Cookbook Name:: glance
# Attributes:: glance
#
# Copyright 2009, Rackspace Hosting, Inc.
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
default["enable_monit"] = false  # OS provides packages
default["developer_mode"] = true  # we want secure passwords by default
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

default["glance"]["image_upload"] = false
default["glance"]["images"] = [ "tty" ]
default["glance"]["image"]["oneiric"] = "http://c250663.r63.cf1.rackcdn.com/ubuntu-11.10-server-uec-amd64-multinic.tar.gz"
default["glance"]["image"]["natty"] = "http://c250663.r63.cf1.rackcdn.com/ubuntu-11.04-server-uec-amd64-multinic.tar.gz"
default["glance"]["image"]["maverick"] = "http://c250663.r63.cf1.rackcdn.com/ubuntu-10.10-server-uec-amd64-multinic.tar.gz"
#default["glance"]["image"]["tty"] = "http://smoser.brickies.net/ubuntu/ttylinux-uec/ttylinux-uec-amd64-12.1_2.6.35-22_1.tar.gz"
default["glance"]["image"]["tty"] = "http://c250663.r63.cf1.rackcdn.com/ttylinux.tgz"
default["glance"]["image"]["cirros"] = "https://launchpadlibrarian.net/83305869/cirros-0.3.0-x86_64-uec.tar.gz"

# logging attribute
default["glance"]["syslog"]["use"] = true
default["glance"]["syslog"]["facility"] = "LOG_LOCAL2"

# platform-specific settings
case platform
when "fedora"
  default["glance"]["platform"] = {
    "mysql_python_packages" => [ "MySQL-python" ],
    "glance_packages" => [ "openstack-glance", "openstack-swift" ],
    "glance_api_service" => "openstack-glance-api",
    "glance_registry_service" => "openstack-glance-registry",
    "package_overrides" => ""
  }
when "ubuntu"
  default["glance"]["platform"] = {
    "mysql_python_packages" => [ "python-mysqldb" ],
    "glance_packages" => [ "glance", "python-swift" ],
    "glance_api_service" => "glance-api",
    "glance_registry_service" => "glance-registry",
    "package_overrides" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
end
