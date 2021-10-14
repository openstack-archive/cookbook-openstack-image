OpenStack Chef Cookbook - image
===============================

.. image:: https://governance.openstack.org/badges/cookbook-openstack-image.svg
    :target: https://governance.openstack.org/reference/tags/index.html

Description
===========

This cookbook installs the OpenStack Image service **Glance** as part of
an OpenStack reference deployment Chef for OpenStack. The `OpenStack
chef-repo`_ contains documentation for using this cookbook in the
context of a full OpenStack deployment.  Glance is installed from
packages, optionally populating the repository with default images.

.. _OpenStack chef-repo: https://opendev.org/openstack/openstack-chef

https://docs.openstack.org/glance/latest

Requirements
============

- Chef 16 or higher
- Chef Workstation 21.10.640 for testing (also includes Berkshelf for
  cookbook dependency resolution)

Platform
========

- ubuntu
- redhat
- centos

Cookbooks
=========

The following cookbooks are dependencies:

- 'openstackclient'
- 'openstack-common', '>= 20.0.0'
- 'openstack-identity', '>= 20.0.0'

Attributes
==========

Please see the extensive inline documentation in ``attributes/*.rb`` for
descriptions of all the settable attributes for this cookbook.

Note that all attributes are in the ``default['openstack']`` "namespace"

The usage of attributes to generate the ``glance-api.conf`` is described
in the openstack-common cookbook.

Recipes
=======

openstack-image::api
--------------------

- Installs the glance-api server

openstack-image::identity_registration
--------------------------------------

- Registers the API endpoint and glance service Keystone user

openstack-image::image-upload
-----------------------------

- Upload image to glance. If you want to upload image during openstack
  installation, you need to add this recipe or the os-image role to the
  run list in a certain role and ensure before this recipe or the
  os-image role glance api recipes have been executed.

openstack-image::swift_store
----------------------------

- Install and configure swift glance packages

Glance Backend
==============

The Glance cookbook currently supports file, swift, and Rackspace Cloud
Files (swift API compliant) backing stores. NOTE: changing the storage
location from cloudfiles to swift (and vice versa) requires that you
manually export and import your stored images.

To enable these features set the following in the default attributes
section in your environment:

Files
-----

.. code:: json

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

Swift
-----

.. code:: json

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

Custom Resources
================

image
-----

Action: ``:upload``

- ``:image_url``: Location of the image to be loaded into Glance.
- ``:image_name``: A name for the image.
- ``:image_type``: ``unknown``, ``qcow``, ``ami``, ``vhd``, ``vmdk``,
  ``vdi``, ``iso``, ``raw``. Defaults of ``unknown`` will use file
  extension '.gz', '.tgz' = ami, '.qcow2', '.img' = qcow.
- ``:image_public``: Set image to be public or private
- ``:image_id``: Set the image ID
- ``:identity_user``: Username of the Keystone admin user.
- ``:identity_pass``: Password for the Keystone admin user.
- ``:identity_tenant``: Name of the Keystone admin user's tenant.
- ``:identity_uri``: URI of the Identity API endpoint.
- ``:identity_user_domain_name``: User domain name for Keystone admin
  user.
- ``:identity_project_domain_name``: Project domain name for Keystone
  admin user.

License and Author
==================

+-----------------+----------------------------------------------------------+
| **Author**      | Justin Shepherd (justin.shepherd@rackspace.com)          |
+-----------------+----------------------------------------------------------+
| **Author**      | Jason Cannavale (jason.cannavale@rackspace.com)          |
+-----------------+----------------------------------------------------------+
| **Author**      | Ron Pedde (ron.pedde@rackspace.com)                      |
+-----------------+----------------------------------------------------------+
| **Author**      | Joseph Breu (joseph.breu@rackspace.com)                  |
+-----------------+----------------------------------------------------------+
| **Author**      | William Kelly (william.kelly@rackspace.com)              |
+-----------------+----------------------------------------------------------+
| **Author**      | Darren Birkett (darren.birkett@rackspace.co.uk)          |
+-----------------+----------------------------------------------------------+
| **Author**      | Evan Callicoat (evan.callicoat@rackspace.com)            |
+-----------------+----------------------------------------------------------+
| **Author**      | Matt Ray (matt@opscode.com)                              |
+-----------------+----------------------------------------------------------+
| **Author**      | Jay Pipes (jaypipes@att.com)                             |
+-----------------+----------------------------------------------------------+
| **Author**      | John Dewey (jdewey@att.com)                              |
+-----------------+----------------------------------------------------------+
| **Author**      | Craig Tracey (craigtracey@gmail.com)                     |
+-----------------+----------------------------------------------------------+
| **Author**      | Sean Gallagher (sean.gallagher@att.com)                  |
+-----------------+----------------------------------------------------------+
| **Author**      | Mark Vanderwiel (vanderwl@us.ibm.com)                    |
+-----------------+----------------------------------------------------------+
| **Author**      | Salman Baset (sabaset@us.ibm.com)                        |
+-----------------+----------------------------------------------------------+
| **Author**      | Chen Zhiwei (zhiwchen@cn.ibm.com)                        |
+-----------------+----------------------------------------------------------+
| **Author**      | Eric Zhou (zyouzhou@cn.ibm.com)                          |
+-----------------+----------------------------------------------------------+
| **Author**      | Jian Hua Geng (gengjh@cn.ibm.com)                        |
+-----------------+----------------------------------------------------------+
| **Author**      | Ionut Artarisi (iartarisi@suse.cz)                       |
+-----------------+----------------------------------------------------------+
| **Author**      | Imtiaz Chowdhury (imtiaz.chowdhury@workday.com)          |
+-----------------+----------------------------------------------------------+
| **Author**      | Jan Klare (j.klare@cloudbau.de)                          |
+-----------------+----------------------------------------------------------+
| **Author**      | Christoph Albers (c.albers@x-ion.de)                     |
+-----------------+----------------------------------------------------------+
| **Author**      | Lance Albertson (lance@osuosl.org)                       |
+-----------------+----------------------------------------------------------+

+-----------------+----------------------------------------------------------+
| **Copyright**   | Copyright (c) 2012, Rackspace US, Inc.                   |
+-----------------+----------------------------------------------------------+
| **Copyright**   | Copyright (c) 2012-2013, Opscode, Inc.                   |
+-----------------+----------------------------------------------------------+
| **Copyright**   | Copyright (c) 2012-2013, AT&T Services, Inc.             |
+-----------------+----------------------------------------------------------+
| **Copyright**   | Copyright (c) 2013, Craig Tracey craigtracey@gmail.com   |
+-----------------+----------------------------------------------------------+
| **Copyright**   | Copyright (c) 2013-2014, IBM Corp.                       |
+-----------------+----------------------------------------------------------+
| **Copyright**   | Copyright (c) 2014, SUSE Linux, GmbH.                    |
+-----------------+----------------------------------------------------------+
| **Copyright**   | Copyright (c) 2019-2021, Oregon State University         |
+-----------------+----------------------------------------------------------+

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at

::

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
