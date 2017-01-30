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

provides :ceph_chef_pool

actions :create, :set, :delete
default_action :create

attribute :name, :kind_of => String, :name_attribute => true

# Group of create and (maybe) set actions:

# The total number of placement groups for the given pool.
attribute :pg_num, :kind_of => Integer, :default => 128
# The total number of placement groups placements for the given pool.
attribute :pgp_num, :kind_of => Integer, :default => 128
# Optional arguments - pool creation
attribute :options, :kind_of => String

# Group of set actions:

# Set the key type
attribute :key, :kind_of => String
# Set the value as an integer or string
attribute :value, :kind_of => [Integer, String]
# Pool type - default is replicated
attribute :type, :kind_of => String, :default => 'replicated'
# Erasure coding profile
attribute :profile, :kind_of => String
# crush_ruleset
attribute :crush_ruleset, :kind_of => Integer, :default => -1
# Crush ruleset name
attribute :crush_ruleset_name, :kind_of => String

attr_accessor :exists
