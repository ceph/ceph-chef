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

# This recipe starts a monitor. The mon.rb recipe must have been called earlier.

include_recipe 'chef-sugar::default'

service_type = node['ceph']['mon']['init_style']

if service_type == 'upstart'
  service 'ceph-mon' do
    provider Chef::Provider::Service::Upstart
    action :enable
  end
  service 'ceph-mon-all' do
    provider Chef::Provider::Service::Upstart
    supports :status => true
    action [:enable, :start]
    subscribes :restart, "template[/etc/ceph/#{node['ceph']['cluster']}.conf]"
  end
else
  if node['ceph']['version'] != 'hammer'
    service 'ceph.target-mon' do
      service_name 'ceph.target'
      provider Chef::Provider::Service::Systemd
      action [:enable, :start]
      subscribes :restart, "template[/etc/ceph/#{node['ceph']['cluster']}.conf]"
    end
    service 'ceph-mon' do
      service_name "ceph-mon@#{node['hostname']}"
      action [:enable, :start]
      only_if { systemd? }
    end
  else
    service 'ceph' do
      supports :restart => true, :status => true
      action [:enable, :start]
      subscribes :restart, "template[/etc/ceph/#{node['ceph']['cluster']}.conf]"
    end
  end
end

# Can include mon_bootstrap_peer_hint recipe here or include it in roles after mon_install.
