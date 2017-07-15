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

include_recipe 'apt'

branch = node['ceph']['branch']

distribution_codename = node['lsb']['codename']

apt_preference 'ceph_repo' do
  glob '*'
  pin 'origin "*.ceph.com"'
  pin_priority '1001'
end

if node['ceph']['repo']['create']
  apt_repository 'ceph' do
    repo_name 'ceph'
    uri node['ceph']['debian'][branch]['repository']
    distribution distribution_codename
    components ['main']
    key node['ceph']['debian'][branch]['repository_key']
  end

  # Only if ceph extras_repo is true
  if node['ceph']['debian']['extras']
    apt_repository 'ceph-extras' do
      repo_name 'ceph-extras'
      uri node['ceph']['debian']['extras']['repository']
      distribution distribution_codename
      components ['main']
      key node['ceph']['debian']['extras']['repository_key']
    end
  end
end
