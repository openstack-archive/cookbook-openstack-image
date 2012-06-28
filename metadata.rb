maintainer        "Opscode, Inc."
license           "Apache 2.0"
description       "The Glance Image Registry and Delivery Service Glance"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "5.0.0"
recipe            "glance::api", "Installs packages required for a glance api server"
recipe            "glance::registry", "Installs packages required for a glance registry server"

%w{ ubuntu fedora }.each do |os|
  supports os
end

%w{ database keystone mysql osops-utils }.each do |dep|
  depends dep
end
