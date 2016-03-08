#
# Author: Chris Jones <cjones303@bloomberg.net>
# Cookbook: ceph
#
# Copyright 2016, Bloomberg Finance L.P.
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

# NOTE: Override the values below in your environment.yaml file
# NOTE: The values you set in pools are critical to a well balanced system.

# RADOSGW - Rados Gateway section
# Update these if you want to setup federated regions and zones
# {region name}-{zone name}-{instance} -- Naming convention used but you can change it
default['ceph']['pools']['radosgw']['federated_regions'] = []
# NOTE: If you use a region then you *must* have at least 1 zone defined and if you use a zone then must at least 1
# region defined.
default['ceph']['pools']['radosgw']['federated_zones'] = []
# Default for federated_instances is 1. If you would like to run multiple instances of radosgw per node then increase
# the federated_instances count. NOTE: When you do this, make sure if you use a load balancer that you account
# for the additional instance(s). Also, instances count *must* never be below 1.
default['ceph']['pools']['radosgw']['federated_instances'] = 1

# These two values *must* be set in your wrapper cookbook if using federated region/zone. They will be the root pool
# name used. For example, region - .us.rgw.root, zone - .us-east.rgw.root (these do not inlcude instances).
default['ceph']['pools']['radosgw']['federated_region_root_pool_name'] = nil
default['ceph']['pools']['radosgw']['federated_zone_root_pool_name'] = nil

# The cluster name will be prefixed to each name during the processing so please only include the actual name.
default['ceph']['pools']['radosgw']['names'] = [
  '.rgw', '.rgw.control', '.rgw.gc', '.rgw.root', '.users.uid',
  '.users.email', '.users.swift', '.users', '.usage', '.log', '.intent-log', '.rgw.buckets', '.rgw.buckets.index',
  '.rgw.buckets.extra'
]

# NOTE: *DO NOT* modify this structure! This is an internal structure that gets dynamically updated IF federated
# options above are updated by wrapper cookbook etc.
default['ceph']['pools']['radosgw']['federated_names'] = []
# 'rbd' federated_names is not used but present - do not remove!
default['ceph']['pools']['rbd']['federated_names'] = []

# NOTE: The radosgw names above will be appended to the federated region/zone names if they are present else just
# the radosgw names will be used.

# The 'ceph''osd''size''max' value will be used if no 'size' value is given in the pools settings!
default['ceph']['pools']['radosgw']['settings'] = {
  'pg_num' => 128, 'pgp_num' => 128, 'options' => '', 'force' => false,
  'calc' => true, 'size' => 3, 'crush_rule_set' => 3, 'chooseleaf' => 'host', 'type' => 'replicated'
}

# RBD - Rados Block Device section
# The cluster name will be prefixed to each name during the processing so please only include the actual name.
# No leading cluster name or leading '.' character.

default['ceph']['pools']['rbd']['names'] = []

default['ceph']['pools']['rbd']['settings'] = {}

# List of pools to process
# If your given environment does not use one of these then override it in your environment.yaml file
# NOTE: Only valid options are 'radosgw' and 'rbd' at present
default['ceph']['pools']['active'] = ['radosgw', 'rbd']
