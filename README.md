Description
===========

This cookbook installs the OpenStack Image service **Glance** as part of an OpenStack reference deployment Chef for OpenStack. The http://github.com/mattray/chef-openstack-repo contains documentation for using this cookbook in the context of a full OpenStack deployment. Glance is installed from packages, optionally populating the repository with default images.

http://glance.openstack.org/

Requirements
============

Chef 0.10.0 or higher required (for Chef environment use).

Cookbooks
---------

The following cookbooks are dependencies:

* openstack-common
* openstack-identity

Usage
=====

api
------
- Installs the glance-api server

client
----
- Install the glance client packages

registry
--------
- Installs the glance-registry server

keystone-registration
---------------------
- Registers the API endpoint and glance service Keystone user

image-upload
------------
- Upload image to glance. If you want to upload image during openstack installation, you need to add this recipe or the os-image role to the run list in a certain role and ensure before this recipe or the os-image role glance api and glance registry recipes have been executed.

The Glance cookbook currently supports file, swift, and Rackspace Cloud Files (swift API compliant) backing stores.  NOTE: changing the storage location from cloudfiles to swift (and vice versa) requires that you manually export and import your stored images.

To enable these features set the following in the default attributes section in your environment:

Files
-----

```json
"openstack": {
    "image": {
        "api": {
            "default_store": "file"
        },
        "upload_images": [
            "cirros"
        ]
    }
}
```

Swift
-----

```json
"openstack": {
    "image": {
        "api": {
            "default_store": "swift"
        },
        "upload_images": [
            "cirros"
        ]
    }
}
```

Providers
=========

image
-----

Action: `:upload`

- `:image_url`: Location of the image to be loaded into Glance.
- `:image_name`: A name for the image.
- `:image_type`: `unknown`, `qcow`, `ami`, `vhd`, `vmdk`, `vdi`, `iso`, `raw`. Defaults of `unknown` will use file extension '.gz', '.tgz' = ami, '.qcow2', '.img' = qcow.
- `:identity_user`: Username of the Keystone admin user.
- `:identity_pass`: Password for the Keystone admin user.
- `:identity_tenant`: Name of the Keystone admin user's tenant.
- `:identity_uri`: URI of the Identity API endpoint.

For testing this provider with ChefSpec, a custom matcher was added to `libraries/matchers.rb`.

Attributes
==========

Attributes for the Image service are in the ['openstack']['image'] namespace.

* `openstack['image']['verbose']` - Enables/disables verbose output for glance services.
* `openstack['image']['debug']` - Enables/disables debug output for glance services.
* `openstack['image']['identity_service_chef_role']` - The name of the Chef role that installs the Keystone Service API
* `openstack['image']['user'] - User glance runs as
* `openstack['image']['group'] - Group glance runs as
* `openstack['image']['db']['username']` - Username for glance database access
* `openstack['image']['api']['adminURL']` - Used when registering image endpoint with keystone
* `openstack['image']['api']['internalURL']` - Used when registering image endpoint with keystone
* `openstack['image']['api']['publicURL']` - Used when registering image endpoint with keystone
* `openstack['image']['service_tenant_name']` - Tenant name used by glance when interacting with keystone - used in the API and registry paste.ini files
* `openstack['image']['service_user']` - User name used by glance when interacting with keystone - used in the API and registry paste.ini files
* `openstack['image']['service_role']` - User role used by glance when interacting with keystone - used in the API and registry paste.ini files
* `openstack['image']['notification_driver']` - Notification driver, default noop.
* `openstack['image']['filesystem_store_metadata_file']` - A path to a JSON file that contains metadata describing the storage system.
* `openstack['image']['filesystem_store_metadata_id']` - The unique id for the filesystem store the images.
* `openstack['image']['filesystem_store_metadata_mountpoint']` - The mount point for the filesystem store the images;
* `openstack['image']['api']['workers']` - Set the number of glance api workers.
* `openstack['image']['api']['show_image_direct_url']` - Allow glance to return URL referencing where data is stored on the backend. Default 'False'
* `openstack['image']['api']['container_formats']` - Supported container formats for glance.
* `openstack['image']['api']['disk_formats']` - Supported disk formats for glance.
* `openstack['image']['api']['auth']['cache_dir']` - Defaults to `/var/cache/glance/api`. Directory where `auth_token` middleware writes certificates for glance-api
* `openstack['image']['registry']['auth']['cache_dir']` - Defaults to `/var/cache/glance/registry`. Directory where `auth_token` middleware writes certificates for glance-registry
* `openstack['image']['api']['auth']['memcached_servers']` - A list of memcached server(s) to use for caching
* `openstack['image']['registry']['auth']['memcached_servers']` - A list of memcached server(s) to use for caching
* `openstack['image']['api']['auth']['memcache_security_strategy']` - Whether token data should be authenticated or authenticated and encrypted. Acceptable values are MAC or ENCRYPT
* `openstack['image']['registry']['auth']['memcache_security_strategy']` - Whether token data should be authenticated or authenticated and encrypted. Acceptable values are MAC or ENCRYPT
* `openstack['image']['api']['auth']['memcache_secret_key']` - This string is used for key derivation
* `openstack['image']['registry']['auth']['memcache_secret_key']` - This string is used for key derivation
* `openstack['image']['api']['auth']['hash_algorithms']` - Hash algorithms to use for hashing PKI tokens
* `openstack['image']['registry']['auth']['hash_algorithms']` - Hash algorithms to use for hashing PKI tokens
* `openstack['image']['api']['auth']['cafile']` - A PEM encoded Certificate Authority to use when verifying HTTPs connections.
* `openstack['image']['registry']['auth']['cafile']` - A PEM encoded Certificate Authority to use when verifying HTTPs connections
* `openstack['image']['api']['auth']['insecure']` - Set whether to verify HTTPS connections
* `openstack['image']['registry']['auth']['insecure']` - Set whether to verify HTTPS connections
* `openstack['image']['upload_images']` - Default list of images to upload to the glance repository as part of the install
* `openstack['image']['upload_image']['<imagename>']` - URL location of the `<imagename>` image. There can be multiple instances of this line to define multiple imagess (eg natty, maverick, fedora17 etc)
--- example `openstack['image']['upload_image']['natty']` - "http://c250663.r63.cf1.rackcdn.com/ubuntu-11.04-server-uec-amd64-multinic.tar.gz"
* `openstack['image']['api']['default_store']` - Toggles the backend storage type.  Currently supported is "file", "swift" and "rbd".
* `openstack['image']['api']['stores']` - List of which store classes and store class locations are currently known to glance at startup
* `openstack['image']['api']['block-storage']['cinder_catalog_info']` - Info to match when looking for cinder in the service catalog
* `openstack['image']['api']['block-storage']['cinder_api_insecure']` - Allow to perform insecure SSL requests to cinder (boolean value)
* `openstack['image']['api']['block-storage']['cinder_ca_certificates_file']` - Location of ca certicates file to use for cinder client requests
* `openstack['image']['api']['swift']['store_container']` - Set the container used by glance to store images and snapshots.  Defaults to "glance"
* `openstack['image']['api']['swift']['store_large_object_size']` - Set the size at which glance starts to chunnk files.  Defaults to "200" MB
* `openstack['image']['api']['swift']['store_large_object_chunk_size']` - Set the chunk size for glance.  Defaults to "200" MB
* `openstack['image']['api']['swift']['enable_snet']` - Set whether to use ServiceNET to communicate with the Swift Storage servers. (Rackspace specific option)
* `openstack['image']['api']['swift']['store_region']` -  The region of the swift endpoint to be used for single tenant. This setting is only necessary if the tenant has multiple swift endpoints.
* `openstack['image']['api']['rbd']['rbd_store_ceph_conf']` - Default location of ceph.conf
* `openstack['image']['api']['rbd']['rbd_store_user']` - User for connecting to ceph store
* `openstack['image']['api']['rbd']['rbd_store_pool']` - RADOS pool for images
* `openstack['image']['api']['rbd']['rbd_store_chunk_size']` - Size in MB of chunks for RADOS Store, should be a power of 2
* `openstack['image']['api']['rbd']['key_name']` - The data bag item name used for the Cephx key of the rbd_store_user.
* `openstack['image']['cron']['redirection']` - Redirection of cron output
TODO: Add DB2 support on other platforms

SSL attributes
---------------

Once SSL is enabled, endpoints attributes in Common need to updated to specify the https protocol.

* `openstack['image']['ssl']['enabled']` - Enable SSL for Glance API and registry bind endpoints. Default is false.
* `openstack['image']['ssl']['api']['enabled']` - Enable SSL for Glance API bind endpoint. Default is from ['image']['ssl']['enabled'].
* `openstack['image']['ssl']['registry']['enabled']` - Enable SSL for Glance Registry bind endpoint. Default is from ['image']['ssl']['enabled'].
* `openstack['image']['ssl']['basedir']` -  Base directory for SSL certficate and key file.
* `openstack['image']['ssl']['cert_file']` - Path of the cert file for SSL.
* `openstack['image']['ssl']['key_file']` - Path of the keyfile for SSL.
* `openstack['image']['ssl']['cert_required']` - Client certificate required. Default is False.
* `openstack['image']['ssl']['ca_file']` -  Path of the CA cert file

VMWare attributes
-----------------

* `openstack['image']['api']['vmware']['secret_name']` - VMware databag secret name
* `openstack['image']['api']['vmware']['vmware_server_host']` - ESX/ESXi or vCenter Server target system. e.g. 127.0.0.1, 127.0.0.1:443, www.vmware-infra.com
* `openstack['image']['api']['vmware']['vmware_server_username']` - Server username (string value)
* `openstack['image']['api']['vmware']['vmware_datacenter_path']` - Inventory path to a datacenter (string value)
* `openstack['image']['api']['vmware']['vmware_datastore_name']` - Datastore associated with the datacenter (string value)
* `openstack['image']['api']['vmware']['vmware_api_retry_count']` - The number of times we retry on failures (integer value)
* `openstack['image']['api']['vmware']['vmware_task_poll_interval']` - The interval used for polling remote tasks invoked on VMware ESX/VC server in seconds (integer value)
* `openstack['image']['api']['vmware']['vmware_store_image_dir']` - Absolute path of the folder containing the images in the datastore (string value)
* `openstack['image']['api']['vmware']['vmware_api_insecure']` - Allow to perform insecure SSL requests to the target system (boolean value)

MQ attributes
-------------

* `openstack['image']['mq']['service_type']` - Select qpid or rabbitmq. default rabbitmq
* `openstack['image']['mq']['qpid']['host']` - The qpid host to use
* `openstack['image']['mq']['qpid']['port']` - The qpid port to use
* `openstack['image']['mq']['qpid']['qpid_hosts']` - Qpid hosts. TODO. use only when ha is specified.
* `openstack['image']['mq']['qpid']['username']` - Username for qpid connection
* `openstack['image']['mq']['qpid']['password']` - Password for qpid connection
* `openstack['image']['mq']['qpid']['sasl_mechanisms']` - Space separated list of SASL mechanisms to use for auth
* `openstack['image']['mq']['qpid']['reconnect_timeout']` - The number of seconds to wait before deciding that a reconnect attempt has failed.
* `openstack['image']['mq']['qpid']['reconnect_limit']` - The limit for the number of times to reconnect before considering the connection to be failed.
* `openstack['image']['mq']['qpid']['reconnect_interval_min']` - Minimum number of seconds between connection attempts.
* `openstack['image']['mq']['qpid']['reconnect_interval_max']` - Maximum number of seconds between connection attempts.
* `openstack['image']['mq']['qpid']['reconnect_interval']` - Equivalent to setting qpid_reconnect_interval_min and qpid_reconnect_interval_max to the same value.
* `openstack['image']['mq']['qpid']['heartbeat']` - Seconds between heartbeat messages sent to ensure that the connection is still alive.
* `openstack['image']['mq']['qpid']['protocol']` - Protocol to use. Default tcp.
* `openstack['image']['mq']['qpid']['tcp_nodelay']` - Disable the Nagle algorithm. default disabled.

Messaging Common attributes
---------------------------

* `openstack['image']["control_exchange"]` - The AMQP exchange to connect to if using RabbitMQ or Qpid, defaults to openstack
* `openstack['image']['rpc_backend']` - The messaging module to use
* `openstack['image']['rpc_thread_pool_size']` - Size of RPC thread pool
* `openstack['image']['rpc_conn_pool_size']` - Size of RPC connection pool
* `openstack['image']['rpc_response_timeout']` - Seconds to wait for a response from call or multicall

The following attributes are defined in attributes/default.rb of the common cookbook, but are documented here due to their relevance:

* `openstack['endpoints']['image-api-bind']['host']` - The IP address to bind the api service to
* `openstack['endpoints']['image-api-bind']['port']` - The port to bind the api service to
* `openstack['endpoints']['image-api-bind']['bind_interface']` - The interface name to bind the api service to

* `openstack['endpoints']['image-registry-bind']['host']` - The IP address to bind the registry service to
* `openstack['endpoints']['image-registry-bind']['port']` - The port to bind the registry service to
* `openstack['endpoints']['image-registry-bind']['bind_interface']` - The interface name to bind the registry service to

If the value of the 'bind_interface' attribute is non-nil, then the image service will be bound to the first IP address on that interface.  If the value of the 'bind_interface' attribute is nil, then the image service will be bound to the IP address specified in the host attribute.

Testing
=====

Please refer to the [TESTING.md](TESTING.md) for instructions for testing the cookbook.

Berkshelf
=====

Berks will resolve version requirements and dependencies on first run and
store these in Berksfile.lock. If new cookbooks become available you can run
`berks update` to update the references in Berksfile.lock. Berksfile.lock will
be included in stable branches to provide a known good set of dependencies.
Berksfile.lock will not be included in development branches to encourage
development against the latest cookbooks.

License and Author
==================

Author:: Justin Shepherd (<justin.shepherd@rackspace.com>)
Author:: Jason Cannavale (<jason.cannavale@rackspace.com>)
Author:: Ron Pedde (<ron.pedde@rackspace.com>)
Author:: Joseph Breu (<joseph.breu@rackspace.com>)
Author:: William Kelly (<william.kelly@rackspace.com>)
Author:: Darren Birkett (<darren.birkett@rackspace.co.uk>)
Author:: Evan Callicoat (<evan.callicoat@rackspace.com>)
Author:: Matt Ray (<matt@opscode.com>)
Author:: Jay Pipes (<jaypipes@att.com>)
Author:: John Dewey (<jdewey@att.com>)
Author:: Craig Tracey (<craigtracey@gmail.com>)
Author:: Sean Gallagher (<sean.gallagher@att.com>)
Author:: Mark Vanderwiel (<vanderwl@us.ibm.com>)
Author:: Salman Baset (<sabaset@us.ibm.com>)
Author:: Chen Zhiwei (zhiwchen@cn.ibm.com)
Author:: Eric Zhou (zyouzhou@cn.ibm.com)
Author:: Jian Hua Geng (gengjh@cn.ibm.com)
Author:: Ionut Artarisi (iartarisi@suse.cz)
Author:: Imtiaz Chowdhury (<imtiaz.chowdhury@workday.com>)
Author:: Jan Klare (j.klare@x-ion.de)

Copyright 2012, Rackspace US, Inc.
Copyright 2012-2013, Opscode, Inc.
Copyright 2012-2013, AT&T Services, Inc.
Copyright 2013, Craig Tracey <craigtracey@gmail.com>
Copyright 2013-2014, IBM Corp.
Copyright 2014, SUSE Linux, GmbH.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
