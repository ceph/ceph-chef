# Ceph-Chef Cookbook

[![Join the chat at https://gitter.im/ceph/ceph-chef](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ceph/ceph-chef?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![License](https://img.shields.io/badge/license-Apache_2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

## DESCRIPTION

Installs and configures Ceph, a distributed network storage and filesystem designed to provide excellent performance, reliability, and scalability. Supports *Hammer* and higher releases (nothing below Hammer is supported in this repo).

The current version is focused on installing and configuring Ceph for Ubuntu, CentOS and RHEL.

For documentation on how to use this cookbook, refer to the **[USAGE](#USAGE)** section.

### Recommendation
Also, you can look at **[https://github.com/bloomberg/chef-bcs](https://github.com/bloomberg/chef-bcs)**. That Chef App (repo) uses this repo for Bloomberg's large clusters. The **chef-bcs repo** is an S3 Object Store Cluster used in multiple data centers.

Note: The documentation is a WIP along with a few other features. This repo is actively managed.  

For help, use **[Gitter chat](https://gitter.im/ceph/ceph-chef)**, **[mailing-list](mailto:ceph-users-join@lists.ceph.com)** or **[issues](https://github.com/ceph/ceph-chef/issues)** here in this repo.

### NOTE: Users of ceph-cookbook
The original ceph-cookbook will remain and may continue to be updated (see that repo for specifics). We tried to use some of the interesting features of ceph-cookbook but we added a lot of enhancements and simplifications. Simply replacing ceph-cookbook with ceph-chef will not work without a few modifications. Also, ceph-chef only works with Chef 12.5+ and Hammer and higher. Nothing below the Hammer release of Ceph is supported in this repo. In addition, only **civitweb** is used going forward (not Apache).

NOTE: The current LWRP are using the style prior to Chef version 12.5. There will a new release shortly that will support the now recommended way of handling custom resources. To make that change easier we will be using a helper cookbook called Poise. Using Poise makes creating custom resources and common services very simple.

### Chef

\>= 12.5+

### Platform

Tested as working:

* Ubuntu Trusty (14.04) [Still verifying updates work]
* CentOS (7.1)
* RHEL (7.1)

### Cookbooks

The ceph cookbook requires the following cookbooks from Chef:

https://supermarket.chef.io/

* [apt](https://supermarket.chef.io/cookbooks/apt)
* [apache2](https://supermarket.chef.io/cookbooks/apache2)
* [yum](https://supermarket.chef.io/cookbooks/yum)
* [ntp](https://supermarket.chef.io/cookbooks/ntp)
* [poise](https://supermarket.chef.io/cookbooks/poise)

## USAGE

Ceph cluster design and Ceph support are beyond the scope of this README, please turn to the:

public wiki, mailing lists, visit our IRC channel, or contact Red Hat:

http://ceph.com/docs/master
http://ceph.com/resources/mailing-list-irc/

NOTE: The recommendation above on the Bloomberg Cluster repo will give you a solid design and/or provide ideas and guidance on laying out your Ceph cluster at scale.

This cookbook can be used to implement a chosen cluster design. Most of the configuration is retrieved from node attributes, which can be set by an environment json file or by a wrapper cookbook that updates the attributes directly. A basic cluster configuration will need most of the following attributes:

* `node['ceph']['config']['fsid']` - the cluster UUID
* `node['ceph']['config]'['global']['public network']` - a CIDR specification of the public network
* `node['ceph']['config]'['global']['cluster network']` - a CIDR specification of a separate cluster replication network
* `node['ceph']['config]'['global']['rgw dns name']` -  the main domain of the radosgw daemon

Most notably, the configuration does **NOT** need to set the `mon_initial_members`, because the cookbook does a node search based on tags to find other mons in the same environment.

The other set of attributes that this recipe needs is `node['ceph']['osd_devices']`, which is an array of OSD definitions, similar to the following:

* {'device' => '/dev/sdb'} - Use a full disk for the OSD, with a small partition for the journal
* {'type' => 'directory', 'device' => '/src/node/sdb1/ceph'} - Use a directory, and have a small file for the journal
* {'device' => '/dev/sde', 'dmcrypt' => true} - Store the data encrypted by passing --dmcrypt to `ceph-disk-prepare`
* {'device' => '/dev/sdc', 'journal' => '/dev/sdd2'} - use a full disk for the OSD with a custom partition for the journal on another device such as an SSD or NMVe

### Using a Policy Wrapper Cookbook

To automate setting several of these node attributes, it is recommended to use a policy wrapper cookbook. This allows the ability to use Chef Server cookbook versions along with environment version restrictions to roll out configuration changes in an ordered fashion.

It also can help with automating some settings. For example, a wrapper cookbook could peek at the list of hard drives that `ohai` has found and populate node['ceph']['osd_devices'] accordingly, instead of manually typing them all in:

```ruby
node.override['ceph']['osd_devices'] = node['block_device'].each.reject{ |name, data| name !~ /^sd[b-z]/}.sort.map { |name, data| {'journal' => "/dev/#{name}"} }
```

For best results, the wrapper cookbook's recipe should be placed before the Ceph cookbook in the node's runlist. This will ensure that any attributes are in place before the Ceph cookbook runs and consumes those attributes.

### Ceph Monitor

Ceph monitor nodes should use the ceph-mon role.

Includes:

* ceph-chef::default

### Ceph Metadata Server

Ceph metadata server nodes should use the ceph-mds role.

Includes:

* ceph-chef::default

### Ceph OSD

Ceph OSD nodes should use the ceph-osd role

Includes:

* ceph-chef::default

### Ceph RADOS Gateway (RGW)

Ceph RGW nodes should use the ceph-radosgw role

## ATTRIBUTES

### General

* `node['ceph']['search_environment']` - a custom Chef environment to search when looking for mon nodes. The cookbook defaults to searching the current environment
* `node['ceph']['branch']` - selects whether to install the stable, testing, or dev version of Ceph
* `node['ceph']['version']` - install a version of Ceph that is different than the cookbook default. If this is changed in a wrapper cookbook, some repository urls may also need to be replaced, and they are found in attributes/repo.rb. If the branch attribute is set to dev, this selects the gitbuilder branch to install
* `node['ceph']['extras_repo']` - whether to install the ceph extras repo. The tgt recipe requires this

* `node['ceph']['config']['fsid']` - the cluster UUID
* `node['ceph']['config']['global']['public network']` - a CIDR specification of the public network
* `node['ceph']['config']['global']['cluster network']` - a CIDR specification of a separate cluster replication network
* `node['ceph']['config']['config-sections']` - add to this hash to add extra config sections to the ceph.conf

* `node['ceph']['user_pools']` - an array of pool definitions, with attributes `name`, `pg_num` and `create_options` (optional), that are automatically created when a monitor is deployed

### Ceph MON

* `node['ceph']['config']['mon']` - a hash of settings to save in ceph.conf in the [mon] section, such as `'mon osd nearfull ratio' => '0.75'`

### Ceph OSD

* `node['ceph']['osd_devices']` - an array of OSD definitions for the current node
* `node['ceph']['config']['osd']` - a hash of settings to save in ceph.conf in the [osd] section, such as `'osd max backfills' => 2`
* `node['ceph']['config']['osd']['osd crush location']` - this attribute can be set on a per-node basis to maintain Crush map locations

### Ceph MDS

* `node['ceph']['config']['mds']` - a hash of settings to save in ceph.conf in the [mds] section, such as `'mds cache size' => '100000'`
* `node['ceph']['cephfs_mount']` - where the cephfs recipe should mount CephFS
* `node['ceph']['cephfs_use_fuse']` - whether the cephfs recipe should use the fuse cephfs client. It will default to heuristics based on the kernel version

### Ceph RADOS Gateway (RGW)
### Note: Only supports the newer 'civetweb' version of RGW (not Apache)

* `node['ceph']['radosgw']['api_fqdn']` - what vhost to configure in the web server
* `node['ceph']['radosgw']['admin_email']` - the admin email address to configure in the web server
* `node['ceph']['radosgw']['port']` - Port of the rgw. Defaults to 80
* `node['ceph']['radosgw']['webserver_companion']` - defaults to 'apache2', but it can be set to 'civetweb', or to false in order to leave it unconfigured
* `node['ceph']['radosgw']['path']` - where to save the s3gw.fcgi file
* `node['ceph']['config']['global']['rgw dns name']` -  the main domain of the radosgw daemon, to calculate the bucket name from a subdomain

## Resources/Providers

### ceph\_client

The ceph\_client LWRP provides an easy way to construct a Ceph client key. These keys are needed by anything that needs to talk to the Ceph cluster, including RGW, CephFS, and RBD access.

#### Actions

- :add - creates a client key with the given parameters

#### Parameters

- :name - name attribute. The name of the client key to create. This is used to provide a default for the other parameters
- :caps - A hash of capabilities that should be granted to the client key. Defaults to `{ 'mon' => 'allow r', 'osd' => 'allow r' }`
- :as\_keyring - Whether the key should be saved in a keyring format or a simple secret key. Defaults to true, meaning it is saved as a keyring
- :keyname - The key name to register in Ceph. Defaults to `client.#{name}.#{hostname}`
- :filename - Where to save the key. Defaults to `/etc/ceph/ceph.client.#{name}.#{hostname}.keyring` if `as_keyring` and `/etc/ceph/ceph.client.#{name}.#{hostname}.secret` if not `as_keyring`
- :owner - Which owner should own the saved key file. Defaults to root
- :group - Which group should own the saved key file. Defaults to root
- :mode - What file mode should be applied. Defaults to '00640'

### ceph\_cephfs

The ceph\_cephfs LWRP provides an easy way to mount CephFS. It will automatically create a Ceph client key for the machine and mount CephFS to the specified location. If the kernel client is used, instead of the fuse client, a pre-existing subdirectory of CephFS can be mounted instead of the root.

#### Actions

- :mount - mount CephFS
- :umount - unmount CephFS
- :remount - remount CephFS
- :enable - adds an fstab entry to mount CephFS
- :disable - removes an fstab entry to mount CephFS

#### Parameters

- :directory - name attribute. Where to mount CephFS in the local filesystem
- :use\_fuse - whether to use ceph-fuse or the kernel client to mount the filesystem. ceph-fuse is updated more often, but the kernel client allows for subdirectory mounting. Defaults to true
- :cephfs\_subdir - which CephFS subdirectory to mount. Defaults to '/'. An exception will be thrown if this option is set to anything other than '/' if use\_fuse is also true

### ceph\_pool

The ceph\_pool LWRP provides an easy way to create and delete Ceph pools.

It assumes that connectivity to the cluster is setup and that admin credentials are available from default locations, e.g. /etc/ceph/ceph.client.admin.keyring.

#### Actions

- :add - creates a pool with the given number of placement groups
- :delete - deletes an existing pool

#### Parameters

- :name - the name of the pool to create or delete
- :pg_num - number of placement groups, when creating a new pool
- :create_options - arguments for pool creation (optional)
- :force - force the deletion of an exiting pool along with any data that is stored in it

## DEVELOPING

### Style Guide

This cookbook requires a style guide for all contributions. Travis will automatically verify that every Pull Request follows the style guide.

1. Install [ChefDK](http://downloads.chef.io/chef-dk/)
2. Activate ChefDK's copy of ruby: `eval "$(chef shell-init bash)"`
3. `bundle install`
4. `bundle exec rake style`

### Testing

This cookbook uses Test Kitchen to verify functionality. A Pull Request can't be merged if it causes any of the test configurations to fail.

1. Install [ChefDK](http://downloads.chef.io/chef-dk/)
2. Activate ChefDK's copy of ruby: `eval "$(chef shell-init bash)"`
3. `bundle install`
4. `bundle exec kitchen test aio-debian-74`
5. `bundle exec kitchen test aio-ubuntu-1204`
6. `bundle exec kitchen test aio-ubuntu-1404`

## LICENSE AND AUTHORS
* Author: Chris Jones <cjones303@bloomberg.net>

* Copyright 2016, Bloomberg Finance L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
