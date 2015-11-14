#
# Cookbook Name:: ceph
# Recipe:: radosgw_install
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

include_recipe 'ceph-chef'

node['ceph']['radosgw']['packages'].each do |pck|
  package pck
end

platform_family = node['platform_family']

case platform_family
when 'rhel'
  # Known issue - https://access.redhat.com/solutions/1546303
  # 2015-10-05
  cookbook_file '/etc/init.d/ceph-radosgw' do
    source 'ceph-radosgw'
    owner 'root'
    group 'root'
    mode '0755'
  end
end
