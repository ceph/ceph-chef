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

# Allows for you to define pools for whatever group you wish such as 'radosgw' or 'rbd' or both.
# There is a pools.rb attribute that sets default pool names based on pool types ('radosgw', 'rbd')
# along with settings for each. The settings are applied to ALL pool names in the given list for the given type.
# All of those values can be overridden using the override_attributes in your environment.yaml file.

if node['ceph']['pools']['active']
  node['ceph']['pools']['active'].each do |pool|
    node['ceph']['pools'][pool]['remove']['names'].each do |name|
      pool_name = name.to_s

      ceph_chef_pool pool_name do
        action :delete
        only_if "ceph osd pool get #{pool_name} size"
      end
    end
  end
end
