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

# All versions of Ceph below Infernalis needs selinux disabled or in Permissive mode
execute 'set selinux' do
  command 'setenforce 0'
end

include_recipe 'ceph-chef::fsid'

# Main ceph configuration location
directory '/etc/ceph' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

cookbook_file '/usr/bin/ceph-remove-clean' do
  source 'ceph-remove-clean.yum' if node['platform'] != 'ubuntu'
  source 'ceph-remove-clean.apt' if node['platform'] == 'ubuntu'
  owner 'root'
  group 'root'
  mode '0755'
end

template "/etc/ceph/#{node['ceph']['cluster']}.conf" do
  source 'ceph.conf.erb'
  variables lazy {
    {
      :fsid_secret => ceph_fsid_secret,
      :mon_addresses => ceph_mon_addresses,
      :is_rbd => node['ceph']['is_rbd'],
      :is_rgw => ceph_is_radosgw_node
    }
  }
  mode '0644'
end
