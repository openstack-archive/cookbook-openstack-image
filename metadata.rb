name             'openstack-image'
maintainer       'openstack-chef'
maintainer_email 'openstack-discuss@lists.openstack.org'
license          'Apache-2.0'
description      'Installs and configures the Glance Image Registry and Delivery Service'
version          '18.0.0'

recipe 'openstack-image::api', 'Installs the glance-api server'
recipe 'openstack-image::identity_registration', 'Registers the API endpoint and glance service Keystone user'
recipe 'openstack-image::image-upload', 'Upload image to glance.'
recipe 'openstack-image::swift_store', 'Install and configure swift glance packages'

%w(ubuntu redhat centos).each do |os|
  supports os
end

depends 'openstackclient'
depends 'openstack-common', '>= 18.0.0'
depends 'openstack-identity', '>= 18.0.0'

issues_url 'https://launchpad.net/openstack-chef'
source_url 'https://opendev.org/openstack/cookbook-openstack-image'
chef_version '>= 14.0'
