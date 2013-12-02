# CHANGELOG for cookbook-openstack-image

This file is used to list changes made in each version of cookbook-openstack-image.

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
