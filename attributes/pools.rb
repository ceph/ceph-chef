#
# Author: Chris Jones <cjones303@bloomberg.net>
# Cookbook: ceph
#
# Copyright 2015, Bloomberg Finance L.P.
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
# The cluster name will be prefixed to each name during the processing so please only include the actual name.
# No leading cluster name or leading '.' character.
default['ceph']['pools']['radosgw']['names'] = [
  'rgw', 'rgw.control', 'rgw.gc', 'rgw.root', 'users.uid',
  'users.email', 'users.swift', 'users', 'usage', 'log', 'intent-log', 'rgw.buckets', 'rgw.buckets.index',
  'rgw.buckets.extra'
]

# The 'ceph''osd''size''max' value will be used if no 'size' value is given in the pools settings!
default['ceph']['pools']['radosgw']['settings'] = {
  'pg_num' => 128, 'pgp_num' => 128, 'options' => '', 'force' => false,
  'calc' => true, 'size' => 3, 'crush_rule_set' => 3, 'chooseleaf' => 'host', 'type' => 'replicated'
}

# RBD - Rados Block Device section
# The cluster name will be prefixed to each name during the processing so please only include the actual name.
# No leading cluster name or leading '.' character.

# TODO: Address rbds later...
default['ceph']['pools']['rbd']['names'] = []

default['ceph']['pools']['rbd']['settings'] = {}

# List of pools to process
# If your given environment does not use one of these then override it in your environment.yaml file
default['ceph']['pools']['active'] = ['radosgw', 'rbd']
