name 'openstack-image'
maintainer 'openstack-chef'
maintainer_email 'openstack-dev@lists.openstack.org'
license 'Apache 2.0'
description 'Installs and configures the Glance Image Registry and Delivery Service'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '14.0.0'

%w(ubuntu redhat centos).each do |os|
  supports os
end

depends 'openstack-common', '>= 14.0.0'
depends 'openstack-identity', '>= 14.0.0'
