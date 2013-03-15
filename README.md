Description
===========

This cookbook installs the OpenStack Image service **Glance** as part of an OpenStack
reference deployment Chef for OpenStack. The http://github.com/opscode/openstack-chef-repo
contains documentation for using this cookbook in the context of a full OpenStack deployment.
Glance is installed from packages, optionally populating the repository with default images.

http://glance.openstack.org/

Requirements
============

Chef 0.10.0 or higher required (for Chef environment use).

Cookbooks
---------

The following cookbooks are dependencies:

* database
* keystone">= 2012.2.1"
* mysql
* openstack-common >= 0.1.7

Usage
=====

api
------
-Installs the glance-api server

registry
--------
-Installs the glance-registry server

keystone-registration
---------------------
- Registers the API endpoint and glance service Keystone user

db
--
- Creates the Glance registry database

The Glance cookbook currently supports file, swift, and Rackspace Cloud Files (swift API compliant) backing stores.  NOTE: changing the storage location from cloudfiles to swift (and vice versa) requires that you manually export and import your stored images.

To enable these features set the following in the default attributes section in your environment:

Files
-----

```json
"glance": {
    "api": {
        "default_store": "file"
    },
    "images": [
        "cirros"
    ],
    "image_upload": true
}
```

Swift
-----

```json
"glance": {
    "api": {
        "default_store": "swift"
    },
    "images": [
        "cirros"
    ],
    "image_upload": true
}
```

Providers
=========

`image` (`:action` `:upload`

- `:image_url`: Location of the image to be loaded into Glance.
- `:image_name`: A name for the image.
- `:image_type`: `qcow2` or `ami`. Defaults to `qcow2`.
- `:keystone_user`: Username of the Keystone admin user.
- `:keystone_pass`: Password for the Keystone admin user.
- `:keystone_tenant`: Name of the Keystone admin user's tenant.
- `:keystone_uri`: URI of the Identity API endpoint.

Attributes
==========

* `glance["verbose"]` - Enables/disables verbose output for glance services.
* `glance["debug"]` - Enables/disables debug output for glance services.
* `glance["keystone_service_chef_role"]` - The name of the Chef role that installs the Keystone Service API
* `glance["user"] - User glance runs as
* `glance["group"] - Group glance runs as
* `glance["glance_api_chef_role"]` - The name of the Chef role that installs the Glance API service
* `glance["db"]["username"]` - Username for glance database access
* `glance["api"]["adminURL"]` - Used when registering image endpoint with keystone
* `glance["api"]["internalURL"]` - Used when registering image endpoint with keystone
* `glance["api"]["publicURL"]` - Used when registering image endpoint with keystone
* `glance["service_tenant_name"]` - Tenant name used by glance when interacting with keystone - used in the API and registry paste.ini files
* `glance["service_user"]` - User name used by glance when interacting with keystone - used in the API and registry paste.ini files
* `glance["service_role"]` - User role used by glance when interacting with keystone - used in the API and registry paste.ini files
* `default["glance"]["api"]["auth"]["cache_dir"]` - Defaults to `/var/cache/glance/api`. Directory where `auth_token` middleware writes certificates for glance-api
* `default["glance"]["registry"]["auth"]["cache_dir"]` - Defaults to `/var/cache/glance/registry`. Directory where `auth_token` middleware writes certificates for glance-registry
* `glance["image_upload"]` - Toggles whether to automatically upload images in the `glance["images"]` array
* `glance["images"]` - Default list of images to upload to the glance repository as part of the install
* `glance["image]["<imagename>"]` - URL location of the `<imagename>` image. There can be multiple instances of this line to define multiple imagess (eg natty, maverick, fedora17 etc)
--- example `glance["image]["natty"]` - "http://c250663.r63.cf1.rackcdn.com/ubuntu-11.04-server-uec-amd64-multinic.tar.gz"
* `glance["api"]["default_store"]` - Toggles the backend storage type.  Currently supported is "file" and "swift"
* `glance["api"]["swift"]["store_container"]` - Set the container used by glance to store images and snapshots.  Defaults to "glance"
* `glance["api"]["swift"]["store_large_object_size"]` - Set the size at which glance starts to chunnk files.  Defaults to "200" MB
* `glance["api"]["swift"]["store_large_object_chunk_size"]` - Set the chunk size for glance.  Defaults to "200" MB
* `glance["api"]["rbd"]["rbd_store_ceph_conf"]` - Default location of ceph.conf
* `glance["api"]["rbd"]["rbd_store_user"]` - User for connecting to ceph store
* `glance["api"]["rbd"]["rbd_store_pool"]` - RADOS pool for images
* `glance["api"]["rbd"]["rbd_store_chunk_size"]` - Size in MB of chunks for RADOS Store, should be a power of 2

Testing
=====

This cookbook is using [ChefSpec](https://github.com/acrmp/chefspec) for
testing. Run the following before commiting. It will run your tests,
and check for lint errors.

    $ ./run_tests.bash

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

Copyright 2012, Rackspace US, Inc.
Copyright 2012, Opscode, Inc.
Copyright 2012-2013, AT&T Services, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
