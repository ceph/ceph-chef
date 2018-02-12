#
# Author: Hans Chris Jones <chris.jones@lambdastack.io>
# Cookbook: ceph
# Recipe: mon_start
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

# This recipe stops the ceph mon (only one per node) on the given node

include_recipe 'chef-sugar::default'

service_type = node['ceph']['mon']['init_style']

if service_type == 'upstart'
  service 'ceph-mon' do
    provider Chef::Provider::Service::Upstart
    action :enable
  end
  service 'ceph-mon-all' do
    provider Chef::Provider::Service::Upstart
    action [:stop]
  end
else
  if node['ceph']['version'] != 'hammer'
    service 'ceph.target' do
      service_name 'ceph.target'
      provider Chef::Provider::Service::Systemd
      action [:stop]
    end
  else
    execute 'raw mon start' do
      command 'service ceph stop mon'
    end
  end
end
