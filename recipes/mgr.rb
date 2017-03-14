#
# Author: Chris Jones
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

include_recipe 'ceph-chef'

cluster = node['ceph']['cluster']

if node['ceph']['version'] != 'hammer'
  directory "/var/lib/ceph/mgr/#{cluster}-#{node['hostname']}" do
    owner node['ceph']['owner']
    group node['ceph']['group']
    mode node['ceph']['mode']
    recursive true
    action :create
    not_if "test -d /var/lib/ceph/mgr/#{cluster}-#{node['hostname']}"
  end

  # TODO: Come back to this later...
  
  # keyring = "/var/lib/ceph/mgr/#{cluster}-#{node['hostname']}/keyring"
  #
  # execute 'format ceph-mgr-secret as keyring' do
  #   command lazy { "ceph-authtool --create-keyring #{keyring} --name=mgr. --add-key=#{node['ceph']['mgr-secret']} --cap mon 'allow *'" }
  #   creates keyring
  #   user node['ceph']['owner']
  #   group node['ceph']['group']
  #   only_if { ceph_chef_mgr_secret }
  #   not_if "test -f #{keyring}"
  #   sensitive true if Chef::Resource::Execute.method_defined? :sensitive
  # end
  #
  # # This should only run once to generate the mgr key and then the command above should be executed on other nodes
  # execute 'generate ceph-mgr-secret as keyring' do
  #   command lazy { "ceph-authtool --create-keyring #{keyring} --name=mgr. --gen-key --cap mon 'allow *'" }
  #   creates keyring
  #   user node['ceph']['owner']
  #   group node['ceph']['group']
  #   not_if { ceph_chef_mgr_secret }
  #   not_if "test -f #{keyring}"
  #   notifies :create, 'ruby_block[save ceph_chef_mgr_secret]', :immediately
  #   sensitive true if Chef::Resource::Execute.method_defined? :sensitive
  # end
  #
  # ruby_block 'save ceph_chef_mgr_secret' do
  #   block do
  #     fetch = Mixlib::ShellOut.new("ceph-authtool #{keyring} --print-key --name=mgr.")
  #     fetch.run_command
  #     key = fetch.stdout
  #     node.normal['ceph']['mgr-secret'] = key.delete!("\n")
  #   end
  #   action :nothing
  # end
  #
  # file "/var/lib/ceph/mgr/#{cluster}-#{node['hostname']}/done" do
  #   owner node['ceph']['owner']
  #   group node['ceph']['group']
  #   mode 00644
  # end
  #
  # service_type = node['ceph']['osd']['init_style']
  #
  # filename = case service_type
  #            when 'upstart'
  #              'upstart'
  #            else
  #              'sysvinit'
  #            end
  # file "/var/lib/ceph/mgr/#{cluster}-#{node['hostname']}/#{filename}" do
  #   owner node['ceph']['owner']
  #   group node['ceph']['group']
  #   mode 00644
  # end
  #
  # service 'ceph_mgr' do
  #   case service_type
  #   when 'upstart'
  #     service_name 'ceph-mgr-all-starter'
  #     provider Chef::Provider::Service::Upstart
  #   else
  #     service_name 'ceph'
  #   end
  #   action [:enable, :start]
  #   supports :restart => true
  # end
end
