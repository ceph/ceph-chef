#
# Copyright 2017, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_attribute 'ceph-chef'

# init_style in each major section is allowed so that radosgw or osds or mons etc could be a different OS if required.
# The default is everything on the same OS
default['ceph']['osd']['init_style'] = node['ceph']['init_style']

default['ceph']['osd']['dmcrypt'] = false  # By default don't encrypt osds at rest
default['ceph']['osd']['fs_type'] = 'xfs'  # xfs, ext4, btrfs

# specify the default storage layout to use for OSD
# use filestore as default as bluestore is not supported by the cookbook yet
# supported: 'filestore', 'bluestore' if empty default of ceph-disk will be used
default['ceph']['osd']['type'] = 'filestore'

default['ceph']['osd']['secret_file'] = '/etc/chef/secrets/ceph_chef_osd'

# Defaults for osd pools that are replica pools. Max size is the number of replicas and min is the lowest.
default['ceph']['osd']['size']['max'] = 3
default['ceph']['osd']['size']['min'] = 2

# Default to 2G - Changed this to higher number for a production system.
default['ceph']['osd']['journal']['size'] = 2048

# Override this if you modify the crush map in a production system.
default['ceph']['osd']['crush'] = { 'update_on_start' => true, 'chooseleaf_type' => 1, 'update' => false }

# NOTE: Crush map bucket types: (Context of bucket is not the same as a bucket in RGW)
# type 0 osd
# type 1 host
# type 2 chassis
# type 3 rack
# type 4 row
# type 5 pdu
# type 6 pod
# type 7 room
# type 8 datacenter
# type 9 region
# type 10 root

# MUST be set in the wrapper cookbook or chef-repo like project
default['ceph']['osd']['role'] = 'search-ceph-osd'

# Example of how to set this up via attributes file. Change to support your naming, the correct OSD info etc. this
# is ONLY an example.
default['ceph']['osd']['remove'] = [
  { 'node' => 'ceph-vm3', 'osd' => 11, 'zap' => false, 'partition' => 1, 'data' => '/dev/sdf', 'journal' => '/dev/sdf' }
]

default['ceph']['osd']['add'] = [
  { 'node' => 'ceph-vm3', 'type' => 'hdd', 'data' => '/dev/sde', 'journal' => '/dev/sde' }
]

case node['platform_family']
when 'debian', 'rhel', 'fedora'
  packages = ['ceph']
  packages += debug_packages(packages) if node['ceph']['install_debug']
  default['ceph']['osd']['packages'] = packages
else
  default['ceph']['osd']['packages'] = []
end
