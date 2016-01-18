#
# Author: Chris Jones <cjones303@bloomberg.net>
# Cookbook: ceph
# Recipe: mon_start
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

# This recipe starts a monitor. The mon.rb recipe must have been called earlier.

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
  end
else
  if node['ceph']['version'] != 'hammer'
    #execute 'systemctl mon start' do
    #  command 'systemctl start ceph.target'
    #end
    service 'ceph.target' do
      service_name 'ceph.target'
      provider Chef::Provider::Service::Systemd
      action [:enable, :start]
    end
  else
    service 'ceph_mon' do
      service_name 'ceph'
      supports :restart => true, :status => true
      action [:enable, :start]
    end
  end
end

# Failure may occur when the cluster is first created because the peers may no exist yet so ignore it for now
ceph_chef_mon_addresses.each do |addr|
  execute "peer #{addr}" do
    command "ceph --admin-daemon /var/run/ceph/#{node['ceph']['cluster']}-mon.#{node['hostname']}.asok add_bootstrap_peer_hint #{addr}"
    ignore_failure true
  end
end
