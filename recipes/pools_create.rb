#
# Author: Hans Chris Jones <chris.jones@lambdastack.io>
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
    # Create pool and set type (replicated or erasure - default is replicated)
    if pool == 'radosgw' && !node['ceph']['pools']['radosgw']['federated_regions'].empty? && node['ceph']['pools']['radosgw']['federated_enable']
      # NOTE: *Must* have federated_regions and federated_zones if doing any federated processing!
      ceph_chef_build_federated_pool(pool)
    end

    # If federation is used then inside this function it will loop through the federated pool names and created them.
    # If federation is not used then the standard pool names and settings will be used.
    ceph_chef_pool_create(pool)
  end
end

# Safety precaution so as to not overload the mon nodes.
bash 'wait-for-pgs-creating' do
  action :nothing
  user 'root'
  # code "sleep 1; while ceph -s | grep -v mdsmap | grep creating >/dev/null 2>&1; do echo Waiting for new pgs to create...; sleep 1; done"
  code 'while [ $(ceph -s | grep creating -c) -gt 0 ]; do echo -n .;sleep 1; done'
end
