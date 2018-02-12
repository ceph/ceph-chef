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

# NOTE: There is a default erasure coding profile built into Ceph. However, it is highly recommended that you
# create other profiles. Also, once a pool has been created using erasure coding it can NOT be changed. If you wish
# to change the pool you will actually need to create a new pool with a different erasure coding profile and
# then move the objects from the old pool to the new pool and then remove the old pool.

# There are recipes here that help do the moving of the objects (future)

include_recipe 'ceph-chef'

# Creates (sets) the specified erasure coding profile to be used by the pools
node['ceph']['pools']['erasure_coding']['profiles'].each do |profile|
  ceph_chef_erasure profile['profile'].to_s do
    plugin profile['plugin']
    directory profile['directory']
    key_value profile['key_value']
    force profile['force']
    technique profile['technique']
    ruleset_root profile['ruleset_root'] if node['ceph']['osd']['crush']['update'] && (!profile['ruleset_root'].nil? && !profile['ruleset_root'].empty?)
    ruleset_failure_domain profile['ruleset_failure_domain'] if node['ceph']['osd']['crush']['update'] && (!profile['ruleset_failure_domain'].nil? && !profile['ruleset_failure_domain'].empty?)
    action :set
    not_if "ceph osd erasure-code-profile get #{profile['profile']}"
  end
end
