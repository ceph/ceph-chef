#
# Author: Hans Chris Jones <chris.jones@lambdastack.io>
# Cookbook: ceph
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

# NOTE: The values you set in pools are critical to a well balanced system.

##### Erasure coding
# NOTE: This is already created so don't try to set it again. Also, add to the key_value hash if more options are needed.
default['ceph']['pools']['erasure_coding']['profiles'] = [{ 'profile' => 'custom-default', 'directory' => '/usr/lib64/ceph/erasure-code', 'plugin' => 'jerasure', 'force' => true, 'ruleset_root' => '', 'key_value' => { 'k' => 3, 'm' => 2 } }]
# NOTE: Override the above array with the profile(s) you want for your environment. The above is simply an example!!

# There may be more but at the initial time of this code the following are valid plugins:
# jerasure (default), SHEC, isa, lrc
# You can check the following docs http://docs.ceph.com/docs/master/rados/operations/erasure-code-profile/
# If you want to override settings of an existing profile then set the 'force' to true (default is false)

# NOTE: Each plugin has it's own set of unique parameters so handle this use the following hash variable
# to add the unique values. For example, {"k" => 8, "m" => 3}. Add more to the hash if needed.
#####

# RADOSGW - Rados Gateway section

# 'version' causes the newer version of the pool creation to be called
default['ceph']['pools']['version'] = 2

# Update these if you want to setup federated regions and zones
# {region name}-{zone name}-{instance} -- Naming convention used but you can change it
default['ceph']['pools']['radosgw']['federated_enable'] = false
default['ceph']['pools']['radosgw']['federated_regions'] = []
default['ceph']['pools']['radosgw']['federated_enable_regions_zones'] = false
default['ceph']['pools']['radosgw']['federated_master_zone'] = ''
default['ceph']['pools']['radosgw']['federated_master_zone_port'] = 80
# NOTE: If you use a region then you *must* have at least 1 zone defined and if you use a zone then must at least 1
# region defined.
# default['ceph']['pools']['radosgw']['federated_zones'] = []
# Default for federated_zone_instances is 1. If you would like to run multiple instances of radosgw per node then increase
# the federated_zone_instances count. NOTE: When you do this, make sure if you use a load balancer that you account
# for the additional instance(s). Also, there *MUST* always be at least 1 instance value (change the values if desired)
default['ceph']['pools']['radosgw']['federated_zone_instances'] = [{ 'name' => 'inst1', 'port' => 8080, 'region' => '', 'url' => 's3.rgw.ceph.example.com', 'handles' => 5, 'threads' => 100 }]

# These two values *must* be set in your wrapper cookbook if using federated region/zone. They will be the root pool
# name used. For example, region - .us.rgw.root, zone - .us-east.rgw.root (these do not include instances).
default['ceph']['pools']['radosgw']['federated_region_root_pool_name'] = nil
default['ceph']['pools']['radosgw']['federated_zone_root_pool_name'] = nil

# The cluster name will be prefixed to each name during the processing so only include the actual name.
# default['ceph']['pools']['radosgw']['names'] = [
#  '.rgw', '.rgw.control', '.rgw.gc', '.rgw.root', '.users.uid',
#  '.users.email', '.users.swift', '.users', '.usage', '.log', '.intent-log', '.rgw.buckets', '.rgw.buckets.index',
#  '.rgw.buckets.extra'
# ]

# data_percent below should eqaul 100% for the pools listed. The percentage is an estimate of the amount of data each pool will represent. For RGW the .rgw.buckets is the largest and thus requires the highest percentage.
# IF Federation is used then the additional pools will be taken into account within the calculation. See PG calc below. Do not include Federated pools here.
# NOTE: IMPORANT - crush_ruleset -1 means the provider will not attempt to set the crush_ruleset of the pool. IF the value is >= 0 then
# you MUST make sure you modify the crushmap BEFORE creating the pools!
default['ceph']['pools']['radosgw']['pools'] = [
  { 'name' => '.rgw', 'data_percent' => 0.10, 'type' => 'replicated', 'profile' => '', 'crush_ruleset' => -1, 'crush_ruleset_name' => '' },
  { 'name' => '.rgw.control', 'data_percent' => 0.10, 'type' => 'replicated', 'profile' => '', 'crush_ruleset' => -1, 'crush_ruleset_name' => '' },
  { 'name' => '.rgw.gc', 'data_percent' => 0.10, 'type' => 'replicated', 'profile' => '', 'crush_ruleset' => -1, 'crush_ruleset_name' => '' },
  { 'name' => '.rgw.root', 'data_percent' => 0.10, 'type' => 'replicated', 'profile' => '', 'crush_ruleset' => -1, 'crush_ruleset_name' => '' },
  { 'name' => '.users.uid', 'data_percent' => 0.10, 'type' => 'replicated', 'profile' => '', 'crush_ruleset' => -1, 'crush_ruleset_name' => '' },
  { 'name' => '.users.email', 'data_percent' => 0.10, 'type' => 'replicated', 'profile' => '', 'crush_ruleset' => -1, 'crush_ruleset_name' => '' },
  { 'name' => '.users.swift', 'data_percent' => 0.10, 'type' => 'replicated', 'profile' => '', 'crush_ruleset' => -1, 'crush_ruleset_name' => '' },
  { 'name' => '.users', 'data_percent' => 0.10, 'type' => 'replicated', 'profile' => '', 'crush_ruleset' => -1, 'crush_ruleset_name' => '' },
  { 'name' => '.usage', 'data_percent' => 0.10, 'type' => 'replicated', 'profile' => '', 'crush_ruleset' => -1, 'crush_ruleset_name' => '' },
  { 'name' => '.log', 'data_percent' => 0.10, 'type' => 'replicated', 'profile' => '', 'crush_ruleset' => -1, 'crush_ruleset_name' => '' },
  { 'name' => '.intent-log', 'data_percent' => 0.10, 'type' => 'replicated', 'profile' => '', 'crush_ruleset' => -1, 'crush_ruleset_name' => '' },
  { 'name' => '.rgw.buckets', 'data_percent' => 96.90, 'type' => 'replicated', 'profile' => '', 'crush_ruleset' => -1, 'crush_ruleset_name' => '' },
  { 'name' => '.rgw.buckets.index', 'data_percent' => 1.00, 'type' => 'replicated', 'profile' => '', 'crush_ruleset' => -1, 'crush_ruleset_name' => '' },
  { 'name' => '.rgw.buckets.extra', 'data_percent' => 1.00, 'type' => 'replicated', 'profile' => '', 'crush_ruleset' => -1, 'crush_ruleset_name' => '' }
]

default['ceph']['pools']['rbd']['pools'] = []

# This is an internal array that gets built if the Federated option is true. It takes the 'pools' array above and adds the federated names to to.
# So, if you have two vips and Federated is true then this array becomes exactly like the 'pools' array above but twice as large because it cycles through two times (num of vips).
default['ceph']['pools']['radosgw']['federated']['pools'] = []

# If pool names exist in this array they will be removed from Ceph
default['ceph']['pools']['radosgw']['remove']['names'] = []

# NOTE: *DO NOT* modify this structure! This is an internal structure that gets dynamically updated IF federated
# options above are updated by wrapper cookbook etc.
default['ceph']['pools']['radosgw']['federated_names'] = []
# 'rbd' federated_names is not used but present - do not remove!
default['ceph']['pools']['rbd']['federated_names'] = []

# NOTE: The radosgw names above will be appended to the federated region/zone names if they are present else just
# the radosgw names will be used.

# The 'ceph''osd''size''max' value will be used if no 'size' value is given in the pools settings! Size represents replicas.
default['ceph']['pools']['radosgw']['settings'] = {
  'pg_num' => 128, 'pgp_num' => 128, 'options' => '', 'force' => false,
  'calc' => true, 'size' => 3, 'crush_ruleset' => 3, 'chooseleaf' => 'host', 'chooseleaf_type' => 1,
  'type' => 'replicated'
}

# Used for the initial calculation of PGs per pool.
# total_osds - Total number of OSDs on initial setup.
# target_pgs_per_osd - Factor used to represent a 'good' estimate for PGs per OSD. 100 - If you don't expect the size of the cluster
# to change for awhile. 200 - If you believe the size could increase within a reasonable time. 300 - If you believe the cluster will double in size soon.
# replicated_size - If you're using the default 'replicated' model then then number of replicas.
# erasure_size - If you're using erasure coding then the sum of k+m (i.e, 8 + 3 = 11) where k is number of data chunks per piece of data stored and m is the number of coding chunks.
default['ceph']['pools']['pgs']['calc'] = {
  'total_osds' => 12,
  'target_pgs_per_osd' => 200,
  'replicated_size' => 3,
  'erasure_size' => 11
}

default['ceph']['pools']['pgs']['num'] = 128
default['ceph']['pools']['crush']['rule'] = 0

# RBD - Rados Block Device section
# The cluster name will be prefixed to each name during the processing so please only include the actual name.
# No leading cluster name or leading '.' character.

default['ceph']['pools']['rbd']['names'] = []
default['ceph']['pools']['rbd']['remove']['names'] = []
default['ceph']['pools']['rbd']['settings'] = {}

# List of pools to process
# If your given environment does not use one of these then override it in your environment.yaml file
# NOTE: Only valid options are 'radosgw' and 'rbd' at present
default['ceph']['pools']['active'] = ['radosgw', 'rbd']
