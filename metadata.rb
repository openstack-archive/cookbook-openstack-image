name              'openstack-image'
maintainer       'openstack-chef'
maintainer_email 'opscode-chef-openstack@googlegroups.com'
license           'Apache 2.0'
description       'Installs and configures the Glance Image Registry and Delivery Service'
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           '10.1.0'
recipe            'openstack-image::api', 'Installs packages required for a glance api server'
recipe            'openstack-image::client', 'Install packages required for glance client'
recipe            'openstack-image::registry', 'Installs packages required for a glance registry server'
recipe            'openstack-image::identity_registration', 'Registers Glance endpoints and service with Keystone'
recipe            'openstack-image::image_upload', 'Upload image using glance image-create command'

%w{ ubuntu fedora redhat centos suse }.each do |os|
  supports os
end

depends           'openstack-common', '~> 10.0'
depends           'openstack-identity', '~> 10.0'
