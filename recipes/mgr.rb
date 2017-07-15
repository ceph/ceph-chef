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

include_recipe 'ceph-chef'

# NOTE: Only run this recipe after Ceph is running and only on Mon nodes.

if node['ceph']['version'] != 'hammer' && node['ceph']['mgr']['enable']
  # NOTE: Ceph sets up structure automatically so the only thing needed is to enable and start the service

  # cluster = node['ceph']['cluster']
  #
  # directory "/var/lib/ceph/mgr/#{cluster}-#{node['hostname']}" do
  #   owner node['ceph']['owner']
  #   group node['ceph']['group']
  #   mode node['ceph']['mode']
  #   recursive true
  #   action :create
  #   not_if "test -d /var/lib/ceph/mgr/#{cluster}-#{node['hostname']}"
  # end
  #
  # # Put a different ceph-mgr unit file since we don't want it to create keys for us
  # cookbook_file '/usr/lib/systemd/system/ceph-mgr@.service' do
  #   source 'ceph-mgr.service'
  #   mode 0644
  # end
  #
  # keyring = "/var/lib/ceph/mgr/#{cluster}-#{node['hostname']}/keyring"
  #
  # execute 'format ceph-mgr-secret as keyring' do
  #   command lazy { "ceph auth get-or-create mgr.#{node['hostname']} mon 'allow *' > #{keyring}" }
  #   user node['ceph']['owner']
  #   group node['ceph']['group']
  #   # only_if { ceph_chef_mgr_secret }
  #   not_if "test -s #{keyring}"
  #   sensitive true if Chef::Resource::Execute.method_defined? :sensitive
  # end
  #

  service 'ceph_mgr' do
    case node['ceph']['radosgw']['init_style']
    when 'upstart'
      service_name 'ceph-mgr-all-starter'
      provider Chef::Provider::Service::Upstart
    else
      service_name "ceph-mgr@#{node['hostname']}"
    end
    action [:enable, :start]
    supports :restart => true
  end
end
