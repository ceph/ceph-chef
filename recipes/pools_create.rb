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

# Allows for you to define pools for whatever group you wish such as 'radosgw' or 'rbd' or both.
# There is a pools.rb attribute that sets default pool names based on pool types ('radosgw', 'rbd')
# along with settings for each. The settings are applied to ALL pool names in the given list for the given type.
# All of those values can be overridden using the override_attributes in your environment.yaml file.

if node['ceph']['pools']['active']
  node['ceph']['pools']['active'].each do |pool|
    # Create pool and set type (replicated or erasure - default is replicated)
    # #{pool}
    node['ceph']['pools'][pool]['names'].each do |name|
      pool_name = ".#{name}"

      ceph_chef_pool pool_name do
        action :create
        pg_num node['ceph']['pools'][pool]['settings']['pg_num']
        pgp_num node['ceph']['pools'][pool]['settings']['pgp_num']
        type node['ceph']['pools'][pool]['settings']['type']
        options node['ceph']['pools'][pool]['settings']['options'] if node['ceph']['pools'][pool]['settings']['options']
      end

      # TODO: Need to add for calculated PGs options
      # TODO: Need to add crush_rule_set
      # Set...
    end
  end
end
