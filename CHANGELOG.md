# CHANGELOG for cookbook-openstack-image

This file is used to list changes made in each version of cookbook-openstack-image.

## 10.1.0
### Blue print
* Make container_formats and disk_formats configurable

## 10.0.0
* Upgrading to Juno
* filesystem_store_metadata_file in glance-api.conf configurable with node attribute
* Enable rabbit_use_ssl be configurable
* Upgrading berkshelf from 2.0.18 to 3.1.5
* Sync conf files with Juno
* Enable authtoken configurations - including cafile, insecure, memcached_servers, memcache_security_strategy, memcache_secret_key and hash_algorithms
* Fix metadata version constraint for common
* Update conf files with scerect information from mode 644 to 640
* Add attribute for glance-registry workers
* Fix glance registry owner/group to glance
* Fix image upload for tar kernel/initrd images
* Bump Chef gem to 11.16
* Add oslo.messaging attributes for api and registry conf files
* Add support for upload of vhd vmdk vdi iso raw disk formats
* Allow some attributes for cinder storage backend to be configurable
* Add support for multiple rabbit mq hosts
* Make auth_version to be v2.0 in configuration file
* Set the default cinder version to be v2
* stores in glance-api.conf configurable with node attribute

## 9.2.0
* python_packages database client attributes have been migrated to the -common cookbook
* bump berkshelf to 2.0.18 to allow Supermarket support
* fix fauxhai version for suse and redhat
* notifier_strategy in glance-api.conf configurable with node attribute - including attribute-switch for metering

## 9.1.2
### Bug
* Fix image upload to provide error message when type not supported

## 9.1.1
### Bug
* Fix data bag item id issue in recipes/api.rb

## 9.1.0
### Blue print
* Get VMware vCenter password from databag

## 9.0.3
* Fix package reference, need keystone client not keystone

## 9.0.2
* Fix package action to allow updates

## 9.0.1
* Remove policy template

## 9.0.0
* Upgrade to Icehouse

## 8.2.1
### Bug
* Fix the DB2 ODBC driver issue

## 8.2.0
### Blue print
* Use the common auth uri tranformation function and add the auth version to configuration files.

## 8.1.0
* Add client recipe

## 8.0.0
* Updating to Havana Release

## 7.1.1
### Bug
* Relax the dependency on openstack-identity to the 7.x series

## 7.1.0
### Blue print
* Add qpid support to glance. Default is rabbit

## 7.0.6
### Bug
* Do not delete the sqlite database layed down by the glance packages when node.openstack.db.image.db_type is set to sqlite.

## 7.0.5:
* Allow swift packages to be optionally installed.

## 7.0.4:
### Bug
* Fixed <db_type>_python_packages issue when setting node.openstack.db.image.db_type to sqlite.
* Added `converges when configured to use sqlite db backend` test case for this scenario.

## 7.0.3:
* Use the image-api endpoint within the image_image LWRP to enable non-localhost
  uploads.
* Use non-deprecated parameters within the image_image LWRP use of the glance CLI.

## 7.0.2:
* Added cron redirection attribute.

## 7.0.1:
* Corrected inconsistent keystone middleware auth_token for glance-registry.conf.erb.

## 7.0.0:
* Initial release of cookbook-openstack-image.

- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.
