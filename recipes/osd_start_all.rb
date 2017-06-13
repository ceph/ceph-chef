#
# Author:: Hans Chris Jones <chris.jones@lambdastack.io>
# Cookbook Name:: ceph
# Recipe:: osd
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

# Starts ALL of the OSDs on a given node.

service_type = node['ceph']['osd']['init_style']

if service_type == 'upstart'
  service 'ceph_osd' do
    case service_type
    when 'upstart'
      service_name 'ceph-osd-all-starter'
      provider Chef::Provider::Service::Upstart
    end
    action [:enable, :start]
    supports :restart => true
    subscribes :restart, "template[/etc/ceph/#{node['ceph']['cluster']}.conf]"
  end
else
  if node['ceph']['version'] != 'hammer'
    service 'ceph.target-osd' do
      service_name 'ceph.target'
      provider Chef::Provider::Service::Systemd
      action [:enable, :start]
      subscribes :restart, "template[/etc/ceph/#{node['ceph']['cluster']}.conf]"
    end
  else
    service 'ceph' do
      action [:enable]
    end

    execute 'ceph-osd-start' do
      command lazy { 'sudo service ceph start osd' }
      action :run
    end

    execute 'ceph-osd-restart' do
      command lazy { 'sudo service ceph restart osd' }
      action :nothing
      subscribes :run, "template[/etc/ceph/#{node['ceph']['cluster']}.conf]"
    end
  end
end
