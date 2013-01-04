name              "glance"
maintainer        "Opscode, Inc."
license           "Apache 2.0"
description       "Installs and configures the Glance Image Registry and Delivery Service"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "2012.2.0"
name              "glance"
recipe            "glance::api", "Installs packages required for a glance api server"
recipe            "glance::registry", "Installs packages required for a glance registry server"
recipe            "glance::db", "Creates the Glance registry database"

%w{ ubuntu fedora redhat centos }.each do |os|
  supports os
end

depends           "database"
depends           "keystone"
depends           "mysql"
depends           "openstack-common", ">= 0.1.5"
depends           "openstack-utils"
