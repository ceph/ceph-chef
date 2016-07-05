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

# Allows for you to define pools for whatever group you wish such as 'radosgw' or 'rbd' or both.
# There is a pools.rb attribute that sets default pool names based on pool types ('radosgw', 'rbd')
# along with settings for each. The settings are applied to ALL pool names in the given list for the given type.
# All of those values can be overridden using the override_attributes in your environment.yaml file.

if node['ceph']['pools']['active']
  node['ceph']['pools']['active'].each do |pool|
    ceph_chef_pool_set(pool)
    #     node['ceph']['pools'][pool]['names'].each do |name|
    #       unless node['ceph']['cluster'].downcase == 'ceph'
    #         cluster = ".#{node['ceph']['cluster']}"
    #         pool_name = "#{cluster}.#{name}"
    #       else
    #         pool_name = "#{name}"
    #       end
    #
    #       if node['ceph']['pools'][pool]['settings']['type'] == 'replicated'
    #         if node['ceph']['pools'][pool]['settings']['size']
    #           val = node['ceph']['pools'][pool]['settings']['size']
    #         else
    #           val = node['ceph']['osd']['size']['max']
    #         end
    #
    #         # Set replicas...
    #         ceph_chef_pool pool_name do
    #           action :set
    #           key 'size'
    #           value val
    #           # Opposite
    #           only_if "ceph osd pool #{pool_name} size | grep #{val}"
    #         end
    #       end
    #     end
  end
end
